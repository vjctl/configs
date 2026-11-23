#!/usr/bin/env bash
set -euo pipefail

case "$(uname -m)" in
  x86_64|amd64) PLATFORM_ARCH=amd64 ;;
  aarch64|arm64) PLATFORM_ARCH=arm64 ;;
esac

export SSL_CERT_FILE="${SSL_CERT_FILE:-/etc/ssl/certs/ca-certificates.crt}"
export DOCKER_DEFAULT_PLATFORM="linux/$PLATFORM_ARCH"
IMAGE="pi"
TAG="$IMAGE:$PLATFORM_ARCH"
EXTENSIONS="$IMAGE-$PLATFORM_ARCH-extensions"
CACHE="$IMAGE-$PLATFORM_ARCH-cache"
SSL_CERT_ID="ssl_certs"

docker image inspect "$TAG" >/dev/null 2>&1 ||
  docker build --no-cache \
    --secret "id=$SSL_CERT_ID,src=$SSL_CERT_FILE" \
    -t "$TAG" - <<'DOCKERFILE'
FROM node:lts-bookworm-slim
ARG CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
COPY --from=astral/uv /uv /uvx /usr/local/bin/

ENV UV_PYTHON_INSTALL_DIR=/usr/local/share/uv/python \
    UV_PYTHON_BIN_DIR=/usr/local/bin \
    UV_TOOL_DIR=/usr/local/share/uv/tools \
    UV_TOOL_BIN_DIR=/usr/local/bin \
    UV_SYSTEM_CERTS=true \
    SSL_CERT_FILE=${CA_BUNDLE} \
    REQUESTS_CA_BUNDLE=${CA_BUNDLE} \
    CURL_CA_BUNDLE=${CA_BUNDLE} \
    AWS_CA_BUNDLE=${CA_BUNDLE} \
    NODE_EXTRA_CA_CERTS=${CA_BUNDLE} \
    GIT_SSL_CAINFO=${CA_BUNDLE}

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    gh \
    git \
    jq \
    ripgrep \
 && rm -rf /var/lib/apt/lists/*

# RUN git config --system credential.helper '!gh auth git-credential'

RUN --mount=type=secret,id=ssl_certs,required=false \
    if [ -f /run/secrets/ssl_certs ]; then \
        cat /run/secrets/ssl_certs >> "$CA_BUNDLE"; \
    fi

RUN uv python install \
 && PYTHON="$(uv python find)" \
 && ln -sf "$PYTHON" /usr/local/bin/python \
 && ln -sf "$PYTHON" /usr/local/bin/python3 \
 && uv tool install python-lsp-server \
 && uv tool install basedpyright

RUN npm install -g npm@latest \
 && npm install -g --ignore-scripts \
    @earendil-works/pi-coding-agent \
    ketch-cli \
    typescript-language-server

RUN curl -fsSL https://raw.githubusercontent.com/Dicklesworthstone/destructive_command_guard/main/install.sh \
  | bash -s -- --dest /usr/local/bin --no-configure --verify --quiet

COPY --chmod=755 <<'SHIM' /usr/local/bin/xclip
#!/bin/sh
[ -s /clip/img.png ] || exit 1
case "$*" in
  *TARGETS*) echo image/png ;;
  *image/png*) cat /clip/img.png ;;
  *) exit 1 ;;
esac
SHIM

ENV HOME=/root \
    XDG_DATA_HOME=/usr/local/share/xdg \
    XDG_STATE_HOME=/root/.pi \
    PLANNOTATOR_DATA_DIR=/root/.cache/plannotator \
    PLANNOTATOR_REMOTE=1 \
    PLANNOTATOR_AGENT_TERMINAL_REMOTE=1 \
    NPM_PACKAGE_CONFIG_NODE_GYP_DEVDIR=/usr/local \
    NPM_CONFIG_CACHE=/root/.cache/npm \
    NODE_COMPILE_CACHE=/root/.cache/node-compile \
    UV_CACHE_DIR=/tmp/uvcache \
    UV_PYTHON_INSTALL_DIR=/tmp/uvpy

RUN mkdir -p /root/.cache /root/.pi/agent/npm /usr/local/share/xdg \
 && chmod 755 /root \
 && chmod 1777 /root/.cache /root/.pi/agent/npm /usr/local/share/xdg

ENTRYPOINT ["pi"]
DOCKERFILE

export GH_TOKEN="${GH_TOKEN:-$(gh auth token)}"
WORKDIR="/root${PWD#"$HOME"}"

PORT=""
for p in $(seq 19430 19440); do
  (exec 3<>"/dev/tcp/127.0.0.1/$p") 2>/dev/null || { PORT=$p; break; }
done
[ -n "$PORT" ] || { echo "No port in 19430-19440" >&2; exit 1; }

CLIP="$(mktemp -d)"
while :; do pngpaste "$CLIP/img.png" 2>/dev/null || rm -f "$CLIP/img.png"; sleep 0.5; done &
LOOP_PID=$!
cleanup() { kill "$LOOP_PID" 2>/dev/null; rm -rf "$CLIP"; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP

TTY_FLAGS=(-i)
[ -t 0 ] && [ -t 1 ] && TTY_FLAGS=(-it)

docker run --rm "${TTY_FLAGS[@]}" \
  --cap-drop=ALL \
  --security-opt=no-new-privileges:true \
  --pids-limit=512 \
  --user "$(id -u):$(id -g)" \
  -e PLANNOTATOR_PORT="$PORT" \
  -p "127.0.0.1:$PORT:$PORT" \
  -e GH_TOKEN \
  --mount "type=bind,src=${HOME}/devel,dst=/root/devel,readonly" \
  --mount "type=bind,src=${PWD},dst=${WORKDIR}" \
  --mount "type=bind,src=${HOME}/.pi,dst=/root/.pi" \
  --mount "type=volume,src=${EXTENSIONS},dst=/root/.pi/agent/npm" \
  --mount "type=volume,src=${CACHE},dst=/root/.cache" \
  --mount "type=bind,src=${HOME}/.cursor,dst=/root/.cursor" \
  --mount "type=bind,src=${CLIP},dst=/clip,readonly" \
  --workdir "${WORKDIR}" \
  "$TAG" \
  "$@"

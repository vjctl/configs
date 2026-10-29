#!/usr/bin/env bash
set -euo pipefail

case "$(docker info --format '{{.Architecture}}')" in
  x86_64) PLATFORM_ARCH=amd64 ;;
  aarch64) PLATFORM_ARCH=arm64 ;;
esac

export SSL_CERT_FILE="${SSL_CERT_FILE:-/etc/ssl/certs/ca-certificates.crt}"
export DOCKER_DEFAULT_PLATFORM="linux/$PLATFORM_ARCH"
TAG="sandbox:$PLATFORM_ARCH"
EXTENSIONS="sandbox-extensions-$PLATFORM_ARCH"
CACHE="sandbox-cache-$PLATFORM_ARCH"
SSL_CERT_ID="ssl_certs"
docker volume create "$EXTENSIONS" >/dev/null
docker volume create "$CACHE" >/dev/null

docker image inspect "$TAG" >/dev/null 2>&1 ||
  docker buildx build \
    --secret "id=$SSL_CERT_ID,src=$SSL_CERT_FILE" \
    -t "$TAG" - <<'DOCKERFILE'
FROM node:lts-bookworm-slim
COPY --from=astral/uv /uv /uvx /usr/local/bin/

ENV UV_PYTHON_INSTALL_DIR=/usr/local/share/uv/python \
    UV_PYTHON_BIN_DIR=/usr/local/bin \
    UV_TOOL_DIR=/usr/local/share/uv/tools \
    UV_TOOL_BIN_DIR=/usr/local/bin \
    UV_SYSTEM_CERTS=true \
    XDG_DATA_HOME=/usr/local/share/xdg \
    XDG_STATE_HOME=/root/.pi \
    PLANNOTATOR_REMOTE=1

RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    fd-find \
    gh \
    git \
    gnupg \
    jq \
    openssh-client \
    ripgrep

RUN --mount=type=secret,id=ssl_certs,required=false \
    if [ -f /run/secrets/ssl_certs ]; then \
        cat /run/secrets/ssl_certs >> /etc/ssl/certs/ca-certificates.crt; \
    fi

RUN curl -fsSL https://apt.releases.hashicorp.com/gpg \
      | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com bookworm main" \
      > /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends terraform-ls \
    && rm -rf /var/lib/apt/lists/*
RUN uv python install \
 && uv tool install python-lsp-server \
 && uv tool install basedpyright
RUN npm install -g --ignore-scripts \
    @earendil-works/pi-coding-agent \
    typescript \
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

ENTRYPOINT ["pi"]
DOCKERFILE

export GH_TOKEN="$(gh auth token)"

PORT=""
for p in $(seq 19430 19440); do
  (exec 3<>"/dev/tcp/127.0.0.1/$p") 2>/dev/null || { PORT=$p; break; }
done
[ -n "$PORT" ] || { echo "No free port in 19430-19440" >&2; exit 1; }


CLIP="$(mktemp -d)"
while :; do pngpaste "$CLIP/img.png" 2>/dev/null || rm -f "$CLIP/img.png"; sleep 0.5; done &
LOOP_PID=$!
cleanup() { kill "$LOOP_PID" 2>/dev/null; rm -rf "$CLIP"; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP

docker run --rm -it \
  -e PLANNOTATOR_PORT="$PORT" \
  -p "127.0.0.1:$PORT:$PORT" \
  --env-file <(compgen -e | grep -Ev '^(HOME|PATH|PWD|OLDPWD|SHELL|TMPDIR|USER|LOGNAME)$') \
  --mount "type=bind,src=${HOME},dst=/root,readonly" \
  --mount "type=bind,src=${PWD},dst=${PWD}" \
  --mount "type=bind,src=${HOME}/.pi,dst=/root/.pi" \
  --mount "type=volume,src=${EXTENSIONS},dst=/root/.pi/agent/npm" \
  --mount "type=volume,src=${CACHE},dst=/root/.npm" \
  --mount "type=volume,src=${CACHE}-gyp,dst=/root/.cache" \
  --mount "type=bind,src=${HOME}/.cursor,dst=/root/.cursor" \
  --mount "type=bind,src=${CLIP},dst=/clip,readonly" \
  --mount "type=bind,src=${SSL_CERT_FILE},dst=${SSL_CERT_FILE},readonly" \
  --workdir "${PWD}" \
  -e GH_TOKEN \
  "$TAG" \
  "$@"

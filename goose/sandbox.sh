#!/usr/bin/env bash
set -euo pipefail

case "$(docker info --format '{{.Architecture}}')" in
  x86_64) PLATFORM_ARCH=amd64 ;;
  aarch64) PLATFORM_ARCH=arm64 ;;
esac

export SSL_CERT_FILE="${SSL_CERT_FILE:-/etc/ssl/certs/ca-certificates.crt}"
export DOCKER_DEFAULT_PLATFORM="linux/$PLATFORM_ARCH"
IMAGE="goose"
TAG="$IMAGE:$PLATFORM_ARCH"
CACHE="$IMAGE-$PLATFORM_ARCH-cache"
SSL_CERT_ID="ssl_certs"
AGENT_HOME="$HOME/.goose"
mkdir -p "$AGENT_HOME/config" "$AGENT_HOME/share" "$AGENT_HOME/state" "$AGENT_HOME/cursor" "$AGENT_HOME/cursor-config"
docker volume create "$CACHE" >/dev/null

docker image inspect "$TAG" >/dev/null 2>&1 ||
  docker build --no-cache \
    --secret "id=$SSL_CERT_ID,src=$SSL_CERT_FILE" \
    -t "$TAG" - <<'DOCKERFILE'
FROM debian:bookworm-slim
COPY --from=astral/uv /uv /uvx /usr/local/bin/

ENV UV_SYSTEM_CERTS=true \
    HOME=/root \
    PATH="/root/.local/bin:${PATH}" \
    CURSOR_AGENT_COMMAND=agent \
    GOOSE_DISABLE_KEYRING=1 \
    XDG_CONFIG_HOME=/root/.config \
    XDG_DATA_HOME=/root/.local/share \
    XDG_STATE_HOME=/root/.local/state

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    bzip2 \
    ca-certificates \
    curl \
    gh \
    git \
    jq \
    libxcb1 \
    ripgrep \
 && rm -rf /var/lib/apt/lists/*

RUN --mount=type=secret,id=ssl_certs,required=false \
    if [ -f /run/secrets/ssl_certs ]; then \
        cat /run/secrets/ssl_certs >> /etc/ssl/certs/ca-certificates.crt; \
    fi

RUN mkdir -p /root/.cache /root/.config /root/.local/share /root/.local/state \
    && chmod -R 1777 /root /root/.cache

RUN curl -fsSL https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh \
  | CONFIGURE=false bash \
 && curl https://cursor.com/install -fsS | bash

ENTRYPOINT ["goose"]
DOCKERFILE

TTY_FLAGS=(-i)
[ -t 0 ] && [ -t 1 ] && TTY_FLAGS=(-it)

docker run --rm "${TTY_FLAGS[@]}" \
  --cap-drop=ALL \
  --security-opt=no-new-privileges:true \
  --security-opt=seccomp=builtin \
  --pids-limit=512 \
  --user "$(id -u):$(id -g)" \
  --mount "type=bind,src=${AGENT_HOME}/config,dst=/root/.config/goose" \
  --mount "type=bind,src=${AGENT_HOME}/share,dst=/root/.local/share/goose" \
  --mount "type=bind,src=${AGENT_HOME}/state,dst=/root/.local/state/goose" \
  --mount "type=bind,src=${AGENT_HOME}/cursor,dst=/root/.cursor" \
  --mount "type=bind,src=${AGENT_HOME}/cursor-config,dst=/root/.config/cursor" \
  --mount "type=volume,src=${CACHE},dst=/root/.cache" \
  --mount "type=bind,src=${PWD},dst=${PWD}" \
  --mount "type=bind,src=${SSL_CERT_FILE},dst=${SSL_CERT_FILE},readonly" \
  --workdir "${PWD}" \
  "$TAG" \
  "$@"

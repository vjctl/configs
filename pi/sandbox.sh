#!/usr/bin/env bash
set -euo pipefail

IMAGE="sandbox"

case "$(docker info --format '{{.Architecture}}')" in
  x86_64) PLATFORM_ARCH=amd64 ;;
  aarch64) PLATFORM_ARCH=arm64 ;;
esac

if ! docker image inspect "$IMAGE:$PLATFORM_ARCH" >/dev/null 2>&1; then
  docker buildx build --load --platform "linux/$PLATFORM_ARCH" -t "$IMAGE:$PLATFORM_ARCH" - <<'DOCKERFILE'
FROM node:lts-bookworm-slim
COPY --from=astral/uv:0.13.5 /uv /uvx /usr/local/bin/

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
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg \
      | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com bookworm main" \
      > /etc/apt/sources.list.d/hashicorp.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends terraform-ls \
  && rm -rf /var/lib/apt/lists/*
RUN npm install -g --ignore-scripts \
      @earendil-works/pi-coding-agent \
      typescript \
      typescript-language-server \
  && uv tool install python-lsp-server \
  && uv tool install basedpyright

ENTRYPOINT ["pi"]
DOCKERFILE
fi

export GH_TOKEN="$(gh auth token)"

PORT=""
for p in $(seq 19430 19440); do
  (exec 3<>"/dev/tcp/127.0.0.1/$p") 2>/dev/null || { PORT=$p; break; }
done
[ -n "$PORT" ] || { echo "No free port in 19430-19440" >&2; exit 1; }

exec docker run --rm -it --platform "linux/$PLATFORM_ARCH" \
  -e PLANNOTATOR_REMOTE=1 \
  -e PLANNOTATOR_PORT="$PORT" \
  -p "127.0.0.1:$PORT:$PORT" \
  --env-file <(compgen -e | grep -Ev '^(HOME|PATH|PWD|OLDPWD|SHELL|TMPDIR|USER|LOGNAME)$') \
  -e XDG_STATE_HOME=/root/.pi \
  --mount "type=bind,src=${HOME},dst=/root,readonly" \
  --mount "type=bind,src=${PWD},dst=${PWD}" \
  --mount "type=bind,src=${HOME}/.pi,dst=/root/.pi" \
  --mount "type=bind,src=${HOME}/.cursor,dst=/root/.cursor" \
  --workdir "${PWD}" \
  -e GH_TOKEN \
  "$IMAGE:$PLATFORM_ARCH" \
  "$@"

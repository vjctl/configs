#!/usr/bin/env bash
set -euo pipefail

IMAGE="sandbox"
docker build --progress=quiet -t "$IMAGE" - <<'DOCKERFILE'
FROM node:lts-bookworm-slim
COPY --from=astral/uv:0.13.5 /uv /uvx /usr/local/bin/

RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential ca-certificates curl fd-find gh git jq openssh-client ripgrep \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent
RUN npm install -g typescript typescript-language-server
RUN uv tool install python-lsp-server && uv tool install basedpyright

ENTRYPOINT ["pi"]
DOCKERFILE

GH_TOKEN="$(gh auth token)"
export GH_TOKEN

PORT=""
for p in $(seq 19430 19440); do
  if ! (exec 3<>"/dev/tcp/127.0.0.1/$p") 2>/dev/null; then PORT=$p; break; fi
done
[ -n "$PORT" ] || { echo "No free port in 19430-19440" >&2; exit 1; }

exec docker run --rm -it \
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
  "$IMAGE"

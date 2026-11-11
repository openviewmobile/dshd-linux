#!/usr/bin/env bash
# Reproduce the real-provider acceptance run on a packaged Linux build.
#
# Prerequisites:
#   docker build -f Dockerfile -t dshd-linux-test:amd64 --platform linux/amd64 .
#   a DSH home containing profiles/desktop/cordis.patch.yml + credentials
#
# Usage:
#   DSH_TEST_HOME=/tmp/dshd-e2e/home scripts/e2e-provider.sh dist/linux-x64/*.deb
#
# The home directory is mounted read-write (the app writes sessions/logs).
# The provider key is never printed; only the model answer is.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACT="${1:-}"
HOME_DIR="${DSH_TEST_HOME:-}"
IMAGE="${IMAGE:-dshd-linux-test:amd64-e2e}"
NAME="${NAME:-dshd-provider-e2e}"
KEEP="${KEEP:-0}"
PORT="${PORT:-9222}"

if [[ -z "$ARTIFACT" || ! -f "$ARTIFACT" ]]; then
  echo "usage: DSH_TEST_HOME=<dsh-home> $0 <path-to.deb>" >&2
  exit 2
fi
if [[ -z "$HOME_DIR" || ! -f "$HOME_DIR/profiles/desktop/cordis.patch.yml" ]]; then
  echo "DSH_TEST_HOME must contain profiles/desktop/cordis.patch.yml" >&2
  exit 2
fi

ARTIFACT="$(cd "$(dirname "$ARTIFACT")" && pwd)/$(basename "$ARTIFACT")"
HOME_DIR="$(cd "$HOME_DIR" && pwd)"

cleanup() {
  if [[ "$KEEP" != "1" ]]; then
    docker rm -f "$NAME" >/dev/null 2>&1 || true
  else
    echo "kept container: $NAME (docker exec -it $NAME bash)"
  fi
}
trap cleanup EXIT

docker rm -f "$NAME" >/dev/null 2>&1 || true
docker run -d --name "$NAME" --network host \
  -v "$(dirname "$ARTIFACT"):/art:ro" \
  -v "$HOME_DIR:/root/.dsh" \
  -v "$ROOT/scripts:/scripts:ro" \
  -v "$ROOT/evidence:/evidence" \
  "$IMAGE" sleep infinity >/dev/null

docker exec -e PORT="$PORT" "$NAME" bash /scripts/e2e-start-app.sh "$PORT"

docker exec -e CDP_PORT="$PORT" "$NAME" node /scripts/e2e-provider.mjs
docker exec "$NAME" bash -lc 'DISPLAY=:99 import -window root /evidence/linux-provider-e2e.png'
echo "screenshot: evidence/linux-provider-e2e.png"

#!/usr/bin/env bash
# Rebuild all x64 formats in the pre-seeded Flatpak SDK image. Docker NAT is slow;
# route HTTPS through a tiny host-side CONNECT proxy so Flathub/Electron downloads
# use the host network. Requires image dshd-linux-test:flatpak-sdk.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="${IMAGE:-dshd-linux-test:flatpak-sdk}"
SRC_VOL="${SRC_VOL:-dshd-linux-x64-src}"
PROXY_PORT="${PROXY_PORT:-18888}"
CID=""
PROXY_PID=""
cleanup() {
  [ -n "$CID" ] && docker rm -f "$CID" >/dev/null 2>&1 || true
  [ -n "$PROXY_PID" ] && kill "$PROXY_PID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

python3 "$ROOT/scripts/host-connect-proxy.py" --port "$PROXY_PORT" \
  >/tmp/dshd-connect-proxy.log 2>&1 &
PROXY_PID=$!
sleep 1

CID=$(docker run -d --platform linux/amd64 --privileged \
  --add-host=host.docker.internal:host-gateway \
  -e "https_proxy=http://host.docker.internal:$PROXY_PORT" \
  -e "http_proxy=http://host.docker.internal:$PROXY_PORT" \
  -e ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/ \
  -e ELECTRON_BUILDER_BINARIES_MIRROR=https://npmmirror.com/mirrors/electron-builder-binaries/ \
  -v "$SRC_VOL:/src" -v "$ROOT:/work" "$IMAGE" sleep infinity)

docker exec "$CID" bash -lc '
  flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  cd /src
  pnpm --filter @deepseek-ai/dsh-desktop package:linux:x64
'

ART=/src/apps/desktop/.desktop-build/targets/linux-x64/unsigned-artifacts
mkdir -p "$ROOT/dist/linux-x64"
for f in "$ART"/*.AppImage "$ART"/*.deb "$ART"/*.rpm "$ART"/*.flatpak; do
  docker cp "$CID:$f" "$ROOT/dist/linux-x64/"
done
( cd "$ROOT/dist/linux-x64" && shasum -a 256 *.AppImage *.deb *.rpm *.flatpak > SHA256SUMS )
echo "x64 artifacts updated in $ROOT/dist/linux-x64"

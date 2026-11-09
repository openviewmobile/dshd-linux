#!/usr/bin/env bash
# Install the x64 deb in the amd64 test image and verify the Electron window +
# local dsh Host under Xvfb. Run from the repository root.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="${IMAGE:-dshd-linux-test:amd64}"
ART="${ART:-$ROOT/dist/linux-x64}"
OUT="${OUT:-$ROOT/evidence}"
mkdir -p "$OUT"

docker run --rm --platform linux/amd64 \
  -v "$ART:/art:ro" -v "$OUT:/out" \
  "$IMAGE" bash -lc '
    set -e
    apt-get update -qq
    apt-get install -y -qq libnotify4 xdg-utils libsecret-1-0 xauth imagemagick >/tmp/apt.log 2>&1
    dpkg -i /art/*.deb >/tmp/dpkg.log 2>&1
    Xvfb :99 -screen 0 1440x900x24 >/tmp/xvfb.log 2>&1 &
    sleep 2
    DISPLAY=:99 /usr/bin/deepseek-harness --no-sandbox --disable-gpu >/tmp/app.log 2>&1 &
    sleep 18
    pgrep -af "deepseek-harness" | head -5
    grep "dsh web:" /tmp/app.log | tail -1
    DISPLAY=:99 import -window root /out/deb-x64-smoke.png
  '
echo "screenshot: $OUT/deb-x64-smoke.png"

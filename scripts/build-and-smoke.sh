#!/usr/bin/env bash
set -euo pipefail

SRC="${SRC:-/src}"
REPO_URL="${REPO_URL:-https://github.com/deepseek-ai/deepseek-harness.git}"
PATCH="${PATCH:-/work/patches/0001-linux-desktop-target.patch}"
ARCH="$(uname -m)"
case "$ARCH" in
  aarch64|arm64) TARGET="linux-arm64" ;;
  x86_64|amd64) TARGET="linux-x64" ;;
  *) echo "unsupported arch: $ARCH" >&2; exit 1 ;;
esac
TARGET_SUFFIX="${TARGET#linux-}"
case "$TARGET" in
  linux-arm64) OUTDIR="linux-arm64-unpacked" ;;
  *) OUTDIR="linux-unpacked" ;;
esac

if [ ! -d "$SRC/.git" ]; then
  git clone --depth 1 "$REPO_URL" "$SRC"
fi

cd "$SRC"
git reset --hard HEAD >/dev/null
git clean -fd >/dev/null

if ! git apply --check "$PATCH"; then
  echo "patch does not apply cleanly; upstream may have moved" >&2
  exit 1
fi
git apply "$PATCH"

if [ "${SKIP_INSTALL:-0}" != "1" ]; then
  pnpm install --frozen-lockfile --reporter=append-only
fi
pnpm --filter @deepseek-ai/dsh-desktop "package:linux:${TARGET_SUFFIX}:dir"

APP="$SRC/apps/desktop/.desktop-build/targets/${TARGET}/unsigned-artifacts/${OUTDIR}/deepseek-harness"
if [ ! -x "$APP" ]; then
  echo "missing packaged executable: $APP" >&2
  find "$SRC/apps/desktop/.desktop-build" -maxdepth 5 -type f | head -50 >&2 || true
  exit 1
fi

export DISPLAY=:99
Xvfb :99 -screen 0 1440x900x24 >/tmp/xvfb.log 2>&1 &
XVFB_PID=$!
trap 'kill "$XVFB_PID" 2>/dev/null || true' EXIT
sleep 2

"$APP" --no-sandbox --disable-gpu >/tmp/dshd-linux.log 2>&1 &
APP_PID=$!
sleep 20
if ! kill -0 "$APP_PID" 2>/dev/null; then
  echo "app exited early; logs:" >&2
  cat /tmp/dshd-linux.log >&2
  exit 1
fi
import -display :99 -window root /tmp/dshd-linux.png
kill "$APP_PID" 2>/dev/null || true
wait "$APP_PID" 2>/dev/null || true
echo "screenshot: /tmp/dshd-linux.png"
echo "log: /tmp/dshd-linux.log"

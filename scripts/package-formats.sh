#!/usr/bin/env bash
# Build AppImage + deb + rpm + Flatpak for the current Linux architecture.
# Run inside the image built from this project's Dockerfile (flatpak/flatpak-builder included).
set -euo pipefail
SRC="${SRC:-/src}"
REPO_URL="${REPO_URL:-https://github.com/deepseek-ai/deepseek-harness.git}"
UPSTREAM_REF="${UPSTREAM_REF:-}"
PATCH_DIR="${PATCH_DIR:-/work/patches}"
ARCH="$(uname -m)"
case "$ARCH" in
  aarch64|arm64) SUFFIX="arm64" ;;
  x86_64|amd64) SUFFIX="x64" ;;
  *) echo "unsupported arch: $ARCH" >&2; exit 1 ;;
esac

if [ ! -d "$SRC/.git" ]; then
  git clone --depth 1 "$REPO_URL" "$SRC"
fi
cd "$SRC"
if [ -n "$UPSTREAM_REF" ]; then
  git fetch --depth 1 origin "$UPSTREAM_REF"
  git checkout --detach FETCH_HEAD
fi
git reset --hard HEAD >/dev/null
git clean -fd >/dev/null
apply_patch() {
  if git apply --check "$1" 2>/dev/null; then
    git apply "$1"
  elif git apply --reverse --check "$1" 2>/dev/null; then
    echo "already applied: $1"
  else
    echo "patch does not apply: $1" >&2
    exit 1
  fi
}
apply_patch "$PATCH_DIR/0001-linux-desktop-target.patch"
apply_patch "$PATCH_DIR/0002-linux-deb-rpm-flatpak.patch"
apply_patch "$PATCH_DIR/0003-primary-runtime-mirrors.patch"
apply_patch "$PATCH_DIR/0004-flatpak-launch.patch"

if [ "${SKIP_INSTALL:-0}" != "1" ]; then
  pnpm install --frozen-lockfile --reporter=append-only
fi

# The arm64 native LibreOfficeKit package is not published; pnpm leaves an
# incomplete directory behind. Remove it so the runtime uses the bundled WASM
# engine instead of failing in the packaged smoke test.
if [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ]; then
  find "$SRC" -type d -path '*/node_modules/@deepseek-ai/libreoffice-kit-linux-arm64-glibc'     -prune -exec rm -rf {} +
  find "$SRC" -type d -path '*/node_modules/.pnpm/@deepseek-ai+libreoffice-kit-linux-arm64-glibc*'     -prune -exec rm -rf {} +
fi

pnpm --filter @deepseek-ai/dsh-desktop "package:linux:${SUFFIX}"
echo "artifacts: $SRC/apps/desktop/.desktop-build/targets/linux-${SUFFIX}/unsigned-artifacts"
find "$SRC/apps/desktop/.desktop-build/targets/linux-${SUFFIX}/unsigned-artifacts" -maxdepth 1 -type f -printf '%f\\n' | sort

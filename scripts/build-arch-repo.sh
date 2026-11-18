#!/usr/bin/env bash
# Build a local Arch pacman repository from the dshd-linux-bin PKGBUILD and an
# already-downloaded AppImage.  Run on Arch Linux as a non-root user.
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 /path/to/deepseek-harness-*-linux-x86_64-unsigned.AppImage [output-dir]" >&2
  exit 2
fi
if [[ "$(id -u)" -eq 0 ]]; then
  echo "run as a non-root user; makepkg refuses root" >&2
  exit 1
fi
command -v makepkg >/dev/null || { echo "makepkg not found (Arch base-devel required)" >&2; exit 1; }
command -v repo-add >/dev/null || { echo "repo-add not found (pacman required)" >&2; exit 1; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APPIMAGE="$(readlink -f "$1")"
OUT="${2:-$ROOT/dist/arch-repo/x86_64}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$OUT"
cp "$ROOT/packaging/aur/PKGBUILD" "$WORK/PKGBUILD"
cp "$APPIMAGE" "$WORK/"
(
  cd "$WORK"
  DSHD_APPIMAGE_X86_64="$APPIMAGE" makepkg --noconfirm --cleanbuild
)
cp "$WORK"/*.pkg.tar.zst "$OUT/"
repo-add "$OUT/dshd-linux.db.tar.gz" "$OUT"/*.pkg.tar.zst
printf '\nArch repository written to %s\n' "$OUT"
printf 'Serve %s over HTTPS and add it as a pacman Server.\n' "$OUT"

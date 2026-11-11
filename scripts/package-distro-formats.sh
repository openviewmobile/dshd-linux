#!/usr/bin/env bash
# Lint (and optionally build) the distro packaging files added under packaging/.
#
# This script never rebuilds the Electron application.  It checks the wrappers
# around the existing AppImage/RPM artifacts and reports, per channel, whether
# anything beyond static inspection actually ran.
#
# Usage:
#   scripts/package-distro-formats.sh [--build] [aur] [snap] [obs] [nix] [gentoo]
#
# Default: all channels, static checks only.  --build additionally attempts the
# channels whose native toolchain is available on this host; a missing tool is
# reported as SKIP, never as verified.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD=0
CHANNELS=()

for arg in "$@"; do
  case "$arg" in
    --build) BUILD=1 ;;
    -h|--help)
      sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    aur|snap|obs|nix|gentoo) CHANNELS+=("$arg") ;;
    *)
      echo "unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done
if [ ${#CHANNELS[@]} -eq 0 ]; then
  CHANNELS=(aur snap obs nix gentoo)
fi

STATUS_FILE="$(mktemp)"
trap 'rm -f "$STATUS_FILE"' EXIT

PASS=0
FAIL=0
SKIP=0
LINT_STATUS=PASS
BUILD_STATUS="NOT RUN"
VERIFIED=NO

ok()   { printf '  [PASS] %s\n' "$*"; PASS=$((PASS + 1)); }
bad()  { printf '  [FAIL] %s\n' "$*"; FAIL=$((FAIL + 1)); LINT_STATUS=FAIL; }
skip() { printf '  [SKIP] %s\n' "$*"; SKIP=$((SKIP + 1)); }
have() { command -v "$1" >/dev/null 2>&1; }

run_check() {
  local label="$1"
  shift
  local out
  if out=$("$@" 2>&1); then
    ok "$label"
  else
    bad "$label"
    printf '%s\n' "$out" | sed 's/^/         /'
  fi
}

sha256_file() {
  if have sha256sum; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

aur_source_value() {
  local arch="$1"
  env -u DSHD_APPIMAGE_X86_64 -u DSHD_APPIMAGE_AARCH64 bash -c '
    set -euo pipefail
    source "$1"
    eval "printf %s \"\${source_${2}[0]}\""
  ' _ "$ROOT/packaging/aur/PKGBUILD" "$arch"
}

aur_sha_value() {
  local arch="$1"
  env -u DSHD_APPIMAGE_X86_64 -u DSHD_APPIMAGE_AARCH64 bash -c '
    set -euo pipefail
    source "$1"
    eval "printf %s \"\${sha256sums_${2}[0]}\""
  ' _ "$ROOT/packaging/aur/PKGBUILD" "$arch"
}

local_artifact() {
  local arch="$1"
  local var
  case "$arch" in
    x86_64) var="${DSHD_APPIMAGE_X86_64:-}" ;;
    aarch64) var="${DSHD_APPIMAGE_AARCH64:-}" ;;
  esac
  if [ -n "$var" ]; then
    printf '%s\n' "$var"
    return 0
  fi
  case "$arch" in
    x86_64) ls "$ROOT"/dist/linux-x64/*.AppImage 2>/dev/null | head -n1 ;;
    aarch64) ls "$ROOT"/dist/linux-arm64/*.AppImage 2>/dev/null | head -n1 ;;
  esac
}

run_aur() {
  echo "== AUR (packaging/aur) =="
  run_check "PKGBUILD parses with bash -n" bash -n "$ROOT/packaging/aur/PKGBUILD"

  if env -u DSHD_APPIMAGE_X86_64 -u DSHD_APPIMAGE_AARCH64 bash -c '
      set -euo pipefail
      source "$1"
      [[ $pkgname == deepseek-harness-bin ]]
      [[ ${#arch[@]} -eq 2 ]]
      [[ " ${arch[*]} " == *" x86_64 "* && " ${arch[*]} " == *" aarch64 "* ]]
      [[ ${source_x86_64[0]} == *releases/download/v* ]]
      [[ ${source_aarch64[0]} == *releases/download/v* ]]
      [[ ${sha256sums_x86_64[0]} != SKIP && ${sha256sums_aarch64[0]} != SKIP ]]
      [[ ${options[*]} == *"!strip"* ]]
    ' _ "$ROOT/packaging/aur/PKGBUILD"; then
    ok "PKGBUILD variables, both architectures, release URL and non-SKIP checksums"
  else
    bad "PKGBUILD variables/architecture/checksum sanity"
  fi

  if have makepkg; then
    local generated print_dir
    generated="$(mktemp)"
    print_dir="$(mktemp -d)"
    cp "$ROOT/packaging/aur/PKGBUILD" "$print_dir/PKGBUILD"
    # The generated file must represent the published (remote-source) PKGBUILD,
    # not an offline override, and makepkg must be able to write its build dir.
    if (cd "$print_dir" && env -u DSHD_APPIMAGE_X86_64 -u DSHD_APPIMAGE_AARCH64 \
          makepkg --printsrcinfo >"$generated" 2>/dev/null); then
      if diff -u "$ROOT/packaging/aur/.SRCINFO" "$generated" >/dev/null; then
        ok ".SRCINFO matches makepkg --printsrcinfo"
      else
        bad ".SRCINFO is stale (run makepkg --printsrcinfo > .SRCINFO)"
        diff -u "$ROOT/packaging/aur/.SRCINFO" "$generated" | sed 's/^/         /' || true
      fi
    else
      bad "makepkg --printsrcinfo failed"
    fi
    rm -rf "$generated" "$print_dir"

    if have namcap; then
      run_check "namcap PKGBUILD" namcap "$ROOT/packaging/aur/PKGBUILD"
    else
      skip "namcap not installed"
    fi
  else
    skip "makepkg not installed; cannot compare .SRCINFO"
  fi

  local arch art expected actual
  for arch in x86_64 aarch64; do
    art="$(local_artifact "$arch")"
    if [ -z "$art" ] || [ ! -f "$art" ]; then
      skip "no local $arch AppImage to checksum"
      continue
    fi
    expected="$(aur_sha_value "$arch")"
    actual="$(sha256_file "$art")"
    if [ "$expected" = "$actual" ]; then
      ok "local $arch AppImage matches PKGBUILD sha256 ($(basename "$art"))"
    else
      bad "local $arch AppImage sha256 mismatch: PKGBUILD=$expected file=$actual"
    fi
  done

  if [ "$BUILD" = 1 ]; then
    if ! have makepkg; then
      skip "AUR build: makepkg not installed"
    elif [ "$(uname -s)" != "Linux" ]; then
      skip "AUR build: makepkg on a non-Linux host"
    elif [ "$(id -u)" -eq 0 ]; then
      skip "AUR build: makepkg refuses to run as root"
    else
      local art2 tmp
      local -a build_env
      case "$(uname -m)" in
        x86_64|amd64) arch=x86_64 ;;
        aarch64|arm64) arch=aarch64 ;;
        *) arch="" ;;
      esac
      art2="$(local_artifact "${arch:-x86_64}")"
      if [ -z "$art2" ] || [ ! -f "$art2" ]; then
        skip "AUR build: no local AppImage for $(uname -m)"
      else
        tmp="$(mktemp -d)"
        cp "$ROOT/packaging/aur/PKGBUILD" "$tmp/PKGBUILD"
        if [ "$arch" = "aarch64" ]; then
          build_env=(DSHD_APPIMAGE_AARCH64="$art2")
        else
          build_env=(DSHD_APPIMAGE_X86_64="$art2")
        fi
        if [ -n "${DSHD_APPDIR:-}" ]; then
          build_env+=(DSHD_APPDIR="$DSHD_APPDIR")
        fi
        # The offline override removes source_* arrays; prepare() verifies the
        # file hash itself, so makepkg's integrity phase is intentionally skipped.
        if (cd "$tmp" && env "${build_env[@]}" makepkg --noconfirm --nodeps --skipinteg >build.log 2>&1); then
          ok "AUR package built: $(find "$tmp" -maxdepth 1 -name '*.pkg.tar.*' -print -quit)"
          BUILD_STATUS="BUILT"
          VERIFIED="BUILD-ONLY"
        else
          bad "AUR package build failed"
          tail -n 40 "$tmp/build.log" | sed 's/^/         /' || true
          BUILD_STATUS="FAILED"
        fi
        rm -rf "$tmp"
      fi
    fi
  fi
}

yaml_parse() {
  local file="$1"
  if have python3 && python3 -c 'import yaml' >/dev/null 2>&1; then
    python3 - "$file" <<'PY'
import sys, yaml
with open(sys.argv[1], encoding="utf-8") as fh:
    yaml.safe_load(fh)
PY
  elif have ruby; then
    ruby -ryaml -e 'YAML.load_file(ARGV[0])' "$file"
  else
    return 127
  fi
}

run_snap() {
  echo "== Snap (packaging/snap) =="
  if yaml_parse "$ROOT/packaging/snap/snapcraft.yaml"; then
    ok "snapcraft.yaml parses as YAML"
  else
    rc=$?
    if [ "$rc" -eq 127 ]; then
      skip "no Python PyYAML or Ruby YAML parser"
    else
      bad "snapcraft.yaml YAML parse failed"
    fi
  fi

  run_check "snapcraft.yaml has core24 + strict confinement" bash -c '
    set -euo pipefail
    f=$1
    grep -Eq "^base: core24$" "$f"
    grep -Eq "^confinement: strict$" "$f"
    grep -q "command: bin/deepseek-harness" "$f"
    grep -q "desktop: usr/share/applications/deepseek-harness.desktop" "$f"
    grep -q "source-checksum: sha256/" "$f"
    grep -q "personal-files" "$f"
  ' _ "$ROOT/packaging/snap/snapcraft.yaml"

  if have snapcraft; then
    run_check "snapcraft --version" snapcraft --version
  else
    skip "snapcraft not installed; snapcraft.yaml not schema-validated/packed"
  fi

  if [ "$BUILD" = 1 ]; then
    if ! have snapcraft; then
      skip "Snap build: snapcraft not installed"
    elif [ "$(uname -s)" != "Linux" ]; then
      skip "Snap build: snapcraft pack needs a Linux build host"
    else
      local art tmp
      art="$(local_artifact x86_64)"
      if [ -z "$art" ] || [ ! -f "$art" ]; then
        skip "Snap build: no local x86_64 AppImage"
      else
        tmp="$(mktemp -d)"
        cp -a "$ROOT/packaging/snap/." "$tmp/"
        # Replace only the remote source with the local file so the build does
        # not download 350 MB; the checksum is intentionally dropped because
        # snapcraft cannot verify a checksum for a local source.
        python3 - "$tmp/snapcraft.yaml" "$art" <<'PY'
import sys
path, art = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
lines = []
for line in text.splitlines():
    if line.strip().startswith("source: https://"):
        lines.append("    source: " + art)
    elif line.strip().startswith("source-checksum:"):
        continue
    else:
        lines.append(line)
open(path, "w", encoding="utf-8").write("\n".join(lines) + "\n")
PY
        if (cd "$tmp" && snapcraft pack --destructive-mode >build.log 2>&1); then
          ok "Snap packed: $(find "$tmp" -maxdepth 1 -name '*.snap' -print -quit)"
          BUILD_STATUS="BUILT"
          VERIFIED="BUILD-ONLY"
        else
          bad "snapcraft pack failed"
          tail -n 40 "$tmp/build.log" | sed 's/^/         /' || true
          BUILD_STATUS="FAILED"
        fi
        rm -rf "$tmp"
      fi
    fi
  fi
}

run_obs() {
  echo "== openSUSE OBS (packaging/obs) =="
  run_check "_service parses as XML" python3 - "$ROOT/packaging/obs/_service" <<'PY'
import sys, xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
services = root.findall("service")
assert services, "no services"
names = [s.get("name") for s in services]
assert names.count("download_url") == 2, names
assert names.count("verify_file") == 2, names
for svc in services:
    params = {p.get("name"): (p.text or "") for p in svc.findall("param")}
    if svc.get("name") == "verify_file":
        assert len(params.get("checksum", "")) == 64, params
PY

  local spec="$ROOT/packaging/obs/deepseek-harness.spec"
  run_check "spec has prep/install/files and both architectures" bash -c '
    set -euo pipefail
    s=$1
    grep -q "^%prep$" "$s"
    grep -q "^%install$" "$s"
    grep -q "^%files$" "$s"
    grep -q "^ExclusiveArch:.*x86_64.*aarch64" "$s"
    ! grep -q "^BuildArch:.*noarch" "$s"
    grep -q "rpm2cpio" "$s"
    grep -q "desktop-file-validate" "$s"
    grep -q "%attr(4755,root,root)" "$s"
  ' _ "$spec"

  if have rpmspec; then
    run_check "rpmspec -P expands the spec" rpmspec -P "$spec"
  else
    skip "rpmspec not installed; spec not macro-expanded"
  fi
  if have rpmlint; then
    run_check "rpmlint spec" rpmlint "$spec"
  else
    skip "rpmlint not installed"
  fi

  if [ "$BUILD" = 1 ]; then
    if ! have rpmbuild; then
      skip "OBS local rpmbuild: rpmbuild not installed"
    elif [ "$(uname -s)" != "Linux" ]; then
      skip "OBS local rpmbuild: needs a Linux host"
    else
      local art tmp
      art="$(ls "$ROOT"/dist/linux-x64/*.rpm 2>/dev/null | head -n1)"
      if [ -z "$art" ] || [ ! -f "$art" ]; then
        skip "OBS local rpmbuild: no local x86_64 rpm"
      else
        tmp="$(mktemp -d)"
        mkdir -p "$tmp"/{SOURCES,SPECS,BUILD,BUILDROOT,RPMS,SRPMS}
        cp "$art" "$tmp/SOURCES/deepseek-harness-0.2.2-rc.1-linux-x86_64-unsigned.rpm"
        cp "$ROOT/packaging/obs/deepseek-harness.spec" "$tmp/SPECS/"
        if rpmbuild -bb --nodeps \
            --define "_topdir $tmp" \
            --define "_sourcedir $tmp/SOURCES" \
            "$tmp/SPECS/deepseek-harness.spec" >"$tmp/build.log" 2>&1; then
          ok "OBS spec rpm built locally: $(find "$tmp/RPMS" -name '*.rpm' -print -quit)"
          BUILD_STATUS="BUILT"
          VERIFIED="BUILD-ONLY"
        else
          bad "OBS spec rpmbuild failed"
          tail -n 40 "$tmp/build.log" | sed 's/^/         /' || true
          BUILD_STATUS="FAILED"
        fi
        rm -rf "$tmp"
      fi
    fi
  fi
}

run_nix() {
  echo "== Nix (packaging/nix) =="
  if have nix-instantiate; then
    run_check "package.nix parses" nix-instantiate --parse "$ROOT/packaging/nix/package.nix"
    run_check "flake.nix parses" nix-instantiate --parse "$ROOT/packaging/nix/flake.nix"
  else
    skip "nix-instantiate not installed; Nix expressions not parsed"
  fi

  run_check "Nix uses appimageTools + autoPatchelfHook + fhs wrapper" bash -c '
    set -euo pipefail
    p=$1
    f=$2
    grep -q "appimageTools.extractType2" "$p"
    grep -q "autoPatchelfHook" "$p"
    grep -q "makeWrapper" "$p"
    grep -q "sha256-" "$p"
    grep -q "packages = forAllSystems" "$f"
    grep -q "apps = forAllSystems" "$f"
  ' _ "$ROOT/packaging/nix/package.nix" "$ROOT/packaging/nix/flake.nix"

  if [ "$BUILD" = 1 ]; then
    if ! have nix; then
      skip "Nix build: nix not installed"
    else
      if (cd "$ROOT/packaging/nix" && nix build --no-link .#default >/tmp/dshd-nix-build.log 2>&1); then
        ok "nix build .#default"
        BUILD_STATUS="BUILT"
        VERIFIED="BUILD-ONLY"
      else
        bad "nix build .#default failed"
        tail -n 40 /tmp/dshd-nix-build.log | sed 's/^/         /' || true
        BUILD_STATUS="FAILED"
      fi
    fi
  fi
}

run_gentoo() {
  echo "== Gentoo (packaging/gentoo) =="
  local ebuild="$ROOT/packaging/gentoo/deepseek-harness-bin-0.2.2_rc1.ebuild"
  run_check "ebuild parses with bash -n" bash -n "$ebuild"
  run_check "ebuild uses EAPI 8, no stripping, both arches, setuid sandbox" bash -c '
    set -euo pipefail
    e=$1
    grep -q "^EAPI=8$" "$e"
    grep -q "RESTRICT=\"strip\"" "$e"
    grep -q "QA_PREBUILT=\"\\*\"" "$e"
    grep -q "amd64?" "$e"
    grep -q "arm64?" "$e"
    grep -q "fperms 4755 /opt/deepseek-harness/chrome-sandbox" "$e"
    grep -q "doicon -s 1024" "$e"
  ' _ "$ebuild"

  if have pkgcheck; then
    run_check "pkgcheck scan" pkgcheck scan --net "$ROOT/packaging/gentoo" || true
  else
    skip "pkgcheck not installed"
  fi
  if [ "$BUILD" = 1 ]; then
    if have ebuild; then
      skip "Gentoo build: ebuild requires a configured Portage tree/overlay (not attempted here)"
    else
      skip "Gentoo build: ebuild command not installed"
    fi
  fi
}

for channel in "${CHANNELS[@]}"; do
  LINT_STATUS=PASS
  BUILD_STATUS="NOT RUN"
  VERIFIED=NO
  case "$channel" in
    aur) run_aur ;;
    snap) run_snap ;;
    obs) run_obs ;;
    nix) run_nix ;;
    gentoo) run_gentoo ;;
    *) echo "unknown channel: $channel" >&2; exit 2 ;;
  esac

  printf '  -> %-8s lint=%s build=%s verified=%s\n\n' \
    "$channel" "$LINT_STATUS" "$BUILD_STATUS" "$VERIFIED"

  # Persist the per-channel summary for the final table.
  printf '%s|%s|%s|%s\n' "$channel" "$LINT_STATUS" "$BUILD_STATUS" "$VERIFIED" >>"$STATUS_FILE"
done

echo "== Summary =="
printf '%-8s %-6s %-10s %s\n' CHANNEL LINT BUILD VERIFIED
while IFS='|' read -r ch lint build verified; do
  printf '%-8s %-6s %-10s %s\n' "$ch" "$lint" "$build" "$verified"
done <"$STATUS_FILE"
rm -f "$STATUS_FILE"

echo
echo "Lint: PASS=$PASS FAIL=$FAIL SKIP=$SKIP"
if [ "$FAIL" -ne 0 ]; then
  exit 1
fi
echo "Static checks passed.  Channels remain UNVERIFIED unless build=BUILT above;
BUILD-ONLY means the package was produced but was not installed or launched."

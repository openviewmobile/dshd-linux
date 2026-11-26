#!/bin/sh
# Rebuild the unpacked sharp addon against system libvips.
# The AppImage prebuild is linked to libvips-cpp.so.8.18.7, which bundles its
# own GLib. Electron already loads the system GLib, so sharp().metadata()
# segfaults. A system libvips uses the same GLib as Electron.
set -eu
asar=${1:?asar}
dest=${2:?dest node}
work=${3:-}
cleanup=
if [ -z "$work" ]; then
	work=$(mktemp -d)
	cleanup=1
fi
mkdir -p "$work"
if [ -n "$cleanup" ]; then
	trap 'rm -rf "$work"' EXIT
fi

python3 - "$asar" "$work" <<'PY'
import json, struct, sys
from pathlib import Path
asar, out = Path(sys.argv[1]), Path(sys.argv[2])
data = asar.read_bytes()
json_size = struct.unpack_from("<I", data, 12)[0]
header = json.loads(data[16:16 + json_size])
base = 8 + struct.unpack_from("<I", data, 4)[0]
prefixes = (
    "dsh/node_modules/sharp/",
    "dsh/node_modules/detect-libc/",
    "dsh/node_modules/semver/",
    "dsh/node_modules/node-addon-api/",
)

def walk(node, prefix=""):
    for name, child in (node.get("files") or {}).items():
        path = f"{prefix}/{name}" if prefix else name
        if "files" in child:
            yield from walk(child, path)
        else:
            yield path, child

for path, child in walk(header):
    if not path.startswith(prefixes):
        continue
    rel = path.split("dsh/node_modules/", 1)[1]
    target = (out / "sharp" / rel[len("sharp/"):]) if rel.startswith("sharp/") else (out / "node_modules" / rel)
    target.parent.mkdir(parents=True, exist_ok=True)
    off = base + int(child["offset"])
    target.write_bytes(data[off:off + child["size"]])
PY

command -v node >/dev/null || { echo "node is required (net-libs/nodejs)" >&2; exit 1; }
command -v npm >/dev/null || { echo "npm is required (net-libs/nodejs[npm])" >&2; exit 1; }
command -v python3 >/dev/null || { echo "python3 is required (dev-lang/python)" >&2; exit 1; }
command -v pkg-config >/dev/null || { echo "pkg-config is required" >&2; exit 1; }
[ -f /usr/include/node/node.h ] || { echo "node headers missing: /usr/include/node/node.h" >&2; exit 1; }
pkg-config --exists vips-cpp || { echo "system vips-cpp not found (>=media-libs/vips-8.18.7)" >&2; exit 1; }

npm_root=$(npm root -g)
node_gyp=
for candidate in \
	"$npm_root/npm/node_modules/node-gyp/bin/node-gyp.js" \
	"$npm_root/node-gyp/bin/node-gyp.js"
do
	if [ -f "$candidate" ]; then
		node_gyp=$candidate
		break
	fi
done
[ -n "$node_gyp" ] || { echo "node-gyp not found under $npm_root (need net-libs/nodejs[npm])" >&2; exit 1; }

export SHARP_FORCE_GLOBAL_LIBVIPS=1
unset SHARP_IGNORE_GLOBAL_LIBVIPS || true
(
	cd "$work/sharp"
	node "$node_gyp" rebuild --directory=src --nodedir=/usr
)

set -- "$work/sharp/src/build/Release"/sharp-linux-*.node
if [ ! -f "$1" ] || [ "$#" -ne 1 ]; then
	echo "expected one rebuilt sharp addon, found: $*" >&2
	exit 1
fi
built=$1
needed=$(readelf -d "$built")
printf '%s\n' "$needed" | grep -q 'libvips-cpp\.so' || {
	echo "rebuild did not link libvips-cpp" >&2
	exit 1
}
printf '%s\n' "$needed" | grep -q 'libvips-cpp\.so\.8' && {
	echo "rebuild still links the vendored libvips-cpp.so.8" >&2
	exit 1
}
cp "$built" "$dest"
chmod 755 "$dest"

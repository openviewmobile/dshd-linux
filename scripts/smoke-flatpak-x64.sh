#!/usr/bin/env bash
# Docker-only Flatpak GUI smoke test.
#
# Docker's kernel here rejects bwrap's PR_SET_SECCOMP filter. For TESTING ONLY this
# script wraps bwrap, strips --seccomp from the --args stream, and injects PATH.
# It also points electron-wrapper at zypak-wrapper by absolute path because the
# container has no BaseApp PATH. Real Linux hosts need none of this.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="${IMAGE:-dshd-linux-test:flatpak-sdk}"
BUNDLE="${BUNDLE:-$ROOT/dist/linux-x64/deepseek-harness-0.2.2-rc.1-linux-x86_64-unsigned.flatpak}"
OUT="${OUT:-$ROOT/evidence}"
CID="dshd-flatpak-gui"
PROXY_PID=""
cleanup() {
  docker rm -f "$CID" >/dev/null 2>&1 || true
  [ -n "$PROXY_PID" ] && kill "$PROXY_PID" >/dev/null 2>&1 || true
}
trap cleanup EXIT
mkdir -p "$OUT"
docker rm -f "$CID" >/dev/null 2>&1 || true
docker run -d --name "$CID" --platform linux/amd64 --privileged \
  --add-host=host.docker.internal:host-gateway "$IMAGE" sleep infinity >/dev/null
docker cp "$BUNDLE" "$CID:/tmp/app.flatpak"

python3 "$ROOT/scripts/host-connect-proxy.py" --port 18888 \
  >/tmp/dshd-flatpak-proxy.log 2>&1 &
PROXY_PID=$!
sleep 1

docker exec -e https_proxy=http://host.docker.internal:18888 \
  -e http_proxy=http://host.docker.internal:18888 "$CID" bash -lc '
  set -e
  flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak install --user -y --noninteractive org.electronjs.Electron2.BaseApp//24.08 >/tmp/base.log 2>&1 || true
  flatpak install --user -y --noninteractive /tmp/app.flatpak >/tmp/install.log 2>&1
  mv /usr/bin/bwrap /usr/bin/bwrap.real
  cat > /usr/bin/bwrap <<"PY"
#!/usr/bin/python3
import os, sys
raw = sys.argv[1:]
out = ["--setenv", "PATH", "/app/bin:/usr/bin:/bin"]
i = 0
while i < len(raw):
    if raw[i] == "--args":
        fd = int(raw[i + 1])
        chunks = []
        while True:
            b = os.read(fd, 1 << 20)
            if not b: break
            chunks.append(b)
        inner = b"".join(chunks).split(b"\0")
        filtered = []
        j = 0
        while j < len(inner):
            a = inner[j]
            if a in (b"--seccomp", b"--add-seccomp-fd"):
                j += 2
                continue
            if a.startswith(b"--seccomp=") or a.startswith(b"--add-seccomp-fd="):
                j += 1
                continue
            if a: filtered.append(a)
            j += 1
        r, w = os.pipe()
        os.write(w, b"\0".join(filtered))
        os.close(w)
        os.set_inheritable(r, True)
        out += ["--args", str(r)]
        i += 2
    else:
        out.append(raw[i]); i += 1
os.execv("/usr/bin/bwrap.real", ["bwrap"] + out)
PY
  chmod +x /usr/bin/bwrap
  find -L /root/.local/share/flatpak/app/com.deepseek.harness -name electron-wrapper -type f \
    -exec sed -i -E "s|^([[:space:]]*)zypak-wrapper|\\1/app/bin/zypak-wrapper|" {} \;
  Xvfb :99 -screen 0 1440x900x24 >/tmp/xvfb.log 2>&1 &
  sleep 2
  dbus-run-session -- bash -lc "
    DISPLAY=:99 flatpak run --command=/app/bin/electron-wrapper com.deepseek.harness \
      --no-sandbox --disable-gpu >/tmp/app.log 2>&1 &
    sleep 40
    grep -q \"dsh web:\" /tmp/app.log
    DISPLAY=:99 xwininfo -root -tree >/tmp/windows.txt 2>&1
    DISPLAY=:99 import -window root /tmp/flatpak.png
  "
'
docker cp "$CID:/tmp/flatpak.png" "$OUT/flatpak-x64-smoke.png"
docker cp "$CID:/tmp/windows.txt" /tmp/flatpak-windows.txt 2>/dev/null || true
docker cp "$CID:/tmp/app.log" /tmp/flatpak-app.log 2>/dev/null || true
echo "screenshot: $OUT/flatpak-x64-smoke.png"

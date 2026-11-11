#!/bin/bash
# Runs inside the acceptance container: install the deb if needed, start Xvfb and the app.
set -euo pipefail

PORT="${1:-9222}"

if ! dpkg -s deepseek-harness 2>/dev/null | grep -q 'install ok installed'; then
  if ! dpkg -i /art/*.deb >/tmp/dpkg.log 2>&1; then
    cat /tmp/dpkg.log >&2
    echo "base image is missing deb runtime deps; use dshd-linux-test:amd64-e2e" >&2
    exit 1
  fi
fi
dpkg -s deepseek-harness | grep -q 'install ok installed' || { cat /tmp/dpkg.log 2>/dev/null; exit 1; }

Xvfb :99 -screen 0 1440x900x24 >/tmp/xvfb.log 2>&1 &
sleep 2
nohup env DISPLAY=:99 /usr/bin/deepseek-harness \
  --no-sandbox --disable-gpu --disable-dev-shm-usage \
  --remote-debugging-port="$PORT" >/tmp/app.log 2>&1 &

for _ in $(seq 1 60); do
  if curl -fsS "http://127.0.0.1:${PORT}/json/list" >/dev/null 2>&1; then
    exit 0
  fi
  sleep 1
done
echo "app did not expose CDP on ${PORT}" >&2
tail -50 /tmp/app.log >&2
exit 1

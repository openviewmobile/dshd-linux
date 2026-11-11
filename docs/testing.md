# Linux testing

## Docker + Xvfb

```bash
# Project root
docker build -f Dockerfile -t dshd-linux-test .
docker volume create dshd-linux-src
docker run --rm -it \
  -v "$PWD:/work" \
  -v dshd-linux-src:/src \
  dshd-linux-test
# Inside the container
/work/scripts/build-and-smoke.sh
```

The script clones upstream, applies the patches, runs `pnpm install`, builds `linux-<arch>:dir`, launches the app in Xvfb at 1440×900,
checks that the process is alive, and takes a screenshot.

> `/src` must use a Docker named volume; a macOS bind mount triggers `EACCES: permission denied, chmod`
> when electron-builder copies the Windows `node.cmd`.

## Format verification

```bash
# In the project root
gpg --import keys/deepseek-harness-release-signing.asc
scripts/verify-artifacts.sh

# deb GUI smoke test (x64)
scripts/smoke-deb-x64.sh

# Flatpak 25.08 GUI smoke test (x64; inside Docker a test-only bwrap wrapper is needed to bypass seccomp)
flatpak install --user --bundle dist/linux-x64/*.flatpak
flatpak info --show-metadata com.deepseek.harness | grep -E '^(runtime|base|command)='
Xvfb :99 -screen 0 1440x900x24 &
DISPLAY=:99 flatpak run com.deepseek.harness --no-sandbox --disable-gpu --disable-dev-shm-usage
scripts/smoke-flatpak-x64.sh
```

Verified:

- arm64 deb/rpm/Flatpak structure checks; arm64 Flatpak 25.08 has completed install + Xvfb launch;
- deb installs and starts in amd64 Docker + Xvfb, with the window and local host working normally;
- Flatpak 25.08 x64/arm64 bundle install, metadata/runtime checks and Xvfb GUI launch pass (inside Docker a test-only bwrap wrapper is needed to bypass seccomp; not needed on real hardware);
- AppImage launches in Xvfb on arm64/x64;
- `SHA256SUMS` and 16 detached signatures for x64/arm64, AUR, Snap and OBS all pass
  `verify-artifacts.sh`; the record is in `evidence/release-signing.txt`;
- legacy `.doc/.xls/.ppt` converted format by format and render-checked; reproducible script
  `scripts/e2e-legacy-office.sh <fixtures-dir>`, see
  `evidence/legacy-office/README.txt` and `e2e.txt`.

## Real-provider E2E

`scripts/e2e-provider.sh` installs the deb in an amd64 container, starts Xvfb + Electron, sends one real model request over CDP
and asserts the reply, then takes a screenshot.

```bash
# One-time preparation of a test image with the deb runtime dependencies
docker commit dshd-e2e dshd-linux-test:amd64-e2e

DSH_TEST_HOME=/tmp/dshd-provider-home \
  scripts/e2e-provider.sh dist/linux-x64/*.deb
# On success it outputs {"ok":true,...} and writes evidence/linux-provider-e2e.png
```

`DSH_TEST_HOME` must contain `profiles/desktop/cordis.patch.yml` and credentials;
the script does not print the key. The default CDP port is 9222; `PORT=9333` can be used to avoid conflicts with existing instances.

The screen-by-screen checklist and screenshot index are in [acceptance.md](acceptance.md).

## Distribution packaging static validation

```bash
scripts/package-distro-formats.sh
```

Runs the available static checks on the AUR/Snap/OBS/Nix/Gentoo files under `packaging/`; by default it does not download or
build. The real `makepkg` record for AUR is in
[distro-packaging-implementation.md](distro-packaging-implementation.md) §3.1.

## Evidence

- `../evidence/linux-ui-*.png`: first-run welcome screen, Provider, plugin install/enable/uninstall, settings;
- `../evidence/x64-*.txt`, `../evidence/deb-x64-smoke.png`;
- `../evidence/flatpak-*.txt`, `../evidence/SHA256SUMS.*`.

## Not covered

- Long-running operation on a real Linux desktop (non-container);
- Wayland/IME/tray;
- Auto-update;
- Pixel-perfect rendering fidelity for legacy DOC/XLS/PPT beyond the sampled fixtures;

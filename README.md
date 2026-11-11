# DSHD for Linux

> DSHD stands for **DeepSeek Harness Desktop**.

English | [简体中文](README.zh-CN.md)

![DSHD for Linux](promo/out/dshd-linux-social-preview.jpg)

A standalone Linux desktop distribution project for DeepSeek Harness. It adds
Linux x86_64/aarch64 targets to the official desktop application and provides
reproducible packaging, smoke tests, acceptance evidence, and signed release
artifacts.

> This is a packaging and distribution repository, not the upstream application
> source tree. The desktop runtime is bundled from the upstream release.

## What is in this repository

- Linux target patches in `patches/` (desktop target, deb/rpm/Flatpak, runtime
  mirrors, Flatpak launcher);
- AppImage, deb, rpm and Flatpak artifacts for x86_64 and aarch64;
- Arch/AUR, Snap, openSUSE OBS, Nix/NixOS and Gentoo packaging definitions in
  `packaging/`;
- Docker + Xvfb build and smoke scripts in `scripts/`;
- screen-by-screen acceptance evidence in `evidence/`;
- Apache-2.0 project license plus the upstream MIT notice, contributor and
  security guides, issue/PR templates, and CI;
- detached GPG signatures for every release artifact and checksum file.

## Repository layout

```
Dockerfile              build and test image
patches/                Linux target and packaging patches
scripts/                build, package, smoke, signing and verification
evidence/               Xvfb/GUI/artifact evidence
docs/                   design, acceptance, release and signing documentation
dist/                   local artifacts (gitignored)
```

## Quick start

```bash
# From the repository root
docker build -f Dockerfile -t dshd-linux-test .
docker volume create dshd-linux-src
docker run --rm -it -v "$PWD:/work" -v dshd-linux-src:/src dshd-linux-test
# Inside the container
/work/scripts/build-and-smoke.sh
```

See [docs/](docs/README.md) for the complete design, test and release
documentation.

## Distribution support

**Built:** AppImage, deb, rpm and Flatpak for both arm64 and x64. deb, AppImage
and Flatpak have installation/startup verification; rpm has metadata and
unpacking checks. The Flatpak manifest has moved from EOL 24.08 to 25.08 (see
`patches/0002-linux-deb-rpm-flatpak.patch`); **x64 25.08 was rebuilt, installed
and launched** (runtime/sdk/base all 25.08), and **both x64 and arm64 have
installation/startup verification**. Evidence:
[evidence/flatpak-2508-verify.txt](evidence/flatpak-2508-verify.txt),
[evidence/flatpak-2508-arm64-verify.txt](evidence/flatpak-2508-arm64-verify.txt).

**Added:** Arch/AUR `-bin`, Snap, openSUSE OBS, Nix/NixOS and Gentoo packaging
files under `packaging/`. AUR x86_64 was built with `makepkg`, installed with
`pacman -Udd`, and launched under Xvfb. The Snap `.snap` (manual squashfs) and
the OBS spec (local `rpmbuild`) were built, but `snap install` and an OBS
service build were not performed. Nix/Gentoo remain statically checked only.
See [docs/distro-packaging-implementation.md](docs/distro-packaging-implementation.md)
for per-channel status, commands and unverified boundaries, and
[docs/distro-packages.md](docs/distro-packages.md) for format trade-offs.
Alpine is explicitly unsupported because musl is incompatible with Electron's
official glibc binaries.

The goal is to add a **Linux x86_64/aarch64 desktop distribution** on top of the
official `apps/desktop`, functionally aligned with the macOS and Windows desktop
apps, with reproducible Docker-based build and runtime tests.

## What we found

- The official Desktop already ships **linux-x64 / linux-arm64** primary
  runtimes (Node 24, Python, pnpm, Office dependencies); see
  `scripts/primary-runtime/lock.json`.
- The official `electron-builder` configuration already has
  `linux: { target: ['AppImage'] }`.
- But the official release targets are only `mac-arm64`, `mac-x64` and
  `win-x64`; Linux is explicitly excluded by `desktop-build-paths.mjs` and
  `package-target.ts`.
- Linux is therefore not a port from scratch: it wires the existing runtime and
  packaging capability into release targets, then adds:
  - Linux target registration;
  - packaging and smoke-test paths;
  - Docker GUI testing;
  - updater policy; GPG detached signatures are implemented, platform code
    signing is still not.

## Verified builds (2026-11-08)

**The `linux-arm64` desktop app was built and launched in Docker
(`node:24-bookworm` / linux-arm64) + Xvfb.**

- Build command: `pnpm --filter @deepseek-ai/dsh-desktop package:linux:arm64:dir`
- Output: `.desktop-build/targets/linux-arm64/unsigned-artifacts/linux-arm64-unpacked/`
- Launch: `./deepseek-harness --no-sandbox --disable-gpu` under Xvfb 1440x900
- Result: the welcome screen rendered correctly; see
  [evidence/linux-welcome.png](evidence/linux-welcome.png).
- The AppImage was also built and launch-verified:
  `deepseek-harness-0.2.2-rc.1-linux-arm64-unsigned.AppImage` (350 MB); see
  [evidence/linux-appimage.png](evidence/linux-appimage.png).
- Local deliverable copy (gitignored): `dist/linux-arm64/` with `SHA256SUMS`;
  SHA-256 `c93e1a4e9a8a67fe8f4d03e344911ac6bc1687acd7026a57f45cb2da2d4ec00d`.
- Packaged runtime smoke passed: `node 24.21.0`, `koffi`, `sharp`, `pty`,
  `pnpm`, `grep` and `glob` all true; `dsh web` prints a token URL.
- **Office to PDF works.** The Linux package bundles
  `@deepseek-ai/libreoffice-kit-wasm` (0.1.5, backend `wasm`) and requires no
  system LibreOffice. DOCX/XLSX/PPTX to PDF was measured at 4-7 seconds and was
  exercised in a real session through the `office-export-pdf` skill. All three
  formats were converted through the packaged UI and previewed on the right.
  Legacy DOC/XLS/PPT use the same WASM compatibility path and were verified per
  format, with rendered-page evidence:
  [evidence/legacy-office/README.txt](evidence/legacy-office/README.txt),
  [evidence/office-ui.txt](evidence/office-ui.txt),
  [evidence/linux-pdf-pptx-preview.png](evidence/linux-pdf-pptx-preview.png),
  [evidence/linux-pdf-xlsx-preview.png](evidence/linux-pdf-xlsx-preview.png).

> AppImage was verified inside the container with
> `--appimage-extract-and-run --no-sandbox`; for normal distribution, run it
> directly or after `chmod +x` on the target distribution.

> Linux was not a one-line configuration change: target registration, Electron
> paths, packaging/smoke paths, record targets and type declarations all needed
> work. The patches cover those points.

## Acceptance

Real-provider chat, Office to PDF, plugins and settings are documented
screen-by-screen in [docs/acceptance.md](docs/acceptance.md). The reproducible
script is `scripts/e2e-provider.sh`.

## Parity with the macOS/Windows desktop app

| Capability | Linux status |
|---|---|
| Electron shell, Host startup, token to cookie, Web UI | ✅ launched and screenshotted |
| Bundled Node 24 / pnpm / Python / ripgrep | ✅ packaged smoke |
| `koffi` / `sharp` / `node-pty` / `grep` / `glob` | ✅ true |
| First-run welcome, Sign in / Add API Key | ✅ rendered; real-provider E2E passed ([acceptance](docs/acceptance.md)) |
| Plugin install/enable/uninstall | ✅ deb GUI tested (whale pet) |
| Auto-update / platform signing / notarization | ❌ none in v1; ✅ detached GPG signatures (`dist/*/*.asc`) |
| Office to PDF | ✅ built-in WASM engine; DOCX/XLSX/PPTX and legacy DOC/XLS/PPT tested |
| Tray / Wayland / IME / desktop integration | ⏳ unverified; `desktopName` added, needs real hardware |
| x86_64 artifacts | ✅ deb/AppImage/rpm/Flatpak built and launch-verified |

## Linux package formats (AppImage / deb / rpm / Flatpak)

`patches/0002-linux-deb-rpm-flatpak.patch` adds on top of the Linux target:

```js
linux: {
  maintainer: 'DeepSeek Harness <support@deepseek.com>',
  syncDesktopName: true,
  target: ['AppImage', 'deb', 'rpm', 'flatpak'],
},
flatpak: {
  runtimeVersion: '25.08',
  baseVersion: '25.08',
  useWaylandFlags: true,
},
```

Patch order:

```bash
git apply patches/0001-linux-desktop-target.patch
git apply patches/0002-linux-deb-rpm-flatpak.patch
git apply patches/0004-flatpak-launch.patch
pnpm --filter @deepseek-ai/dsh-desktop package:linux:arm64   # or linux:x64
```

Artifacts are written to
`.desktop-build/targets/linux-<arch>/unsigned-artifacts/`:

| Format | Artifact | Install / run |
|---|---|---|
| AppImage | `...AppImage` | `chmod +x` then run |
| deb | `...deb` | `sudo apt install ./...deb` |
| rpm | `...rpm` | `sudo dnf install ./...rpm` |
| Flatpak | `...flatpak` | `flatpak install --user ./...flatpak` |
| Flatpak x64 | 240 MB | 25.08 bundle; `flatpak install --user --bundle` succeeded; GUI launched under Xvfb (welcome screen), see acceptance evidence |

**arm64 verification, 2026-11-08** (Docker `dshd-linux-test:flatpak`):

| Format | Size | Verification |
|---|---|---|
| deb | 262 MB | `dpkg-deb -I`: Package `deepseek-harness`, Architecture `arm64`, Depends/Maintainer/Homepage OK |
| rpm | 216 MB | `rpm -qpi`: Name `deepseek-harness`, Architecture `aarch64`, License/URL OK |
| Flatpak | 226 MB | 24.08 historical artifact; `flatpak install` and sandbox execution passed (25.08 covered on x64) |
| AppImage | 349 MB | existing Xvfb launch verification |

SHA-256 values are in `dist/linux-arm64/SHA256SUMS`
(local artifact directory is gitignored).

> Installing/verifying the Flatpak runtime inside Docker requires `--privileged`
> (bubblewrap creates namespaces); a normal Linux desktop does not. The first
> Flatpak build downloads `org.freedesktop.Platform` / `Sdk` /
> `Electron2.BaseApp` 25.08 from Flathub, several GB; 24.08 is EOL and retained
> only as historical artifact documentation.

Flatpak is produced by electron-builder 26's `flatpak` target plus
`@malept/flatpak-bundler`; the build host needs `flatpak`, `flatpak-builder` and
the Flathub remote, which the Dockerfile includes. The target installs
`org.freedesktop.Platform`, `org.freedesktop.Sdk` and
`org.electronjs.Electron2.BaseApp` 25.08 automatically. The first build needs a
large download. `patches/0004-flatpak-launch.patch` adds
`/app/lib/com.deepseek.harness/dsh-launch` because Flatpak clears `PATH`; the
BaseApp `electron-wrapper` cannot find `zypak-wrapper` otherwise. The launcher
explicitly adds `/app/bin` and overrides the metadata `command`.

> deb/rpm depend on electron-builder's fpm toolchain. The Flatpak output is a
> single-file bundle intended for manual `flatpak install`; it is not submitted
> to Flathub. GPG detached signatures are provided; platform code signing is not.

## Patches

`patches/0001-linux-desktop-target.patch` adds:

- `linux-x64` and `linux-arm64` build targets;
- `package:linux:*` scripts;
- Linux local environment (GPG detached signing, not platform code signing);
- Linux Electron paths;
- Linux packaged smoke paths;
- Linux skips for macOS/Windows proprietary signing and policy.

Apply:

```bash
git clone --depth 1 https://github.com/deepseek-ai/deepseek-harness.git /src
cd /src
git apply /work/patches/0001-linux-desktop-target.patch
git apply /work/patches/0002-linux-deb-rpm-flatpak.patch
git apply /work/patches/0004-flatpak-launch.patch
```

## Docker tests

```bash
# From the repository root
docker build -f Dockerfile -t dshd-linux-test .
docker volume create dshd-linux-src

docker run --rm -it \
  -v "$PWD:/work" \
  -v dshd-linux-src:/src \
  dshd-linux-test
```

Inside the container:

```bash
/work/scripts/build-and-smoke.sh
```

> `/src` must be a Docker named volume. A macOS bind mount such as `/tmp` makes
> electron-builder fail with `EACCES: permission denied, chmod` when copying the
> Windows `node.cmd`.

The script:

1. clones/updates upstream into `/src`;
2. applies the patches;
3. runs `pnpm install`;
4. runs `pnpm --filter @deepseek-ai/dsh-desktop package:linux:arm64:dir`
   (or `linux-x64`);
5. launches `linux-arm64-unpacked/deepseek-harness --no-sandbox` under Xvfb;
6. captures a screenshot and checks the window/log.

Build deb/rpm/Flatpak (not the `--dir` smoke package):

```bash
/work/scripts/package-formats.sh
```

## Known risks

- The first `pnpm install` downloads Electron/Node/Python wheels and can take a
  long time.
- Electron inside Docker needs `--no-sandbox`; test use only.
- Linux auto-update and platform code signing are not implemented. Detached GPG
  signatures and `SHA256SUMS` are available; updates remain manual or use a
  custom updater.
- The upstream Desktop has Linux code paths but no official Linux release
  acceptance; each capability must be tested here.

## x64 build (2026-11-08)

The Dockerfile is parameterized so an x86_64 toolchain can be built on an arm64
host with regional mirrors:

```bash
docker build --platform linux/amd64 \
  --build-arg NODE_IMAGE=node:24-bookworm-slim-amd64 \
  --build-arg APT_MIRROR=http://mirrors.aliyun.com \
  --build-arg NPM_REGISTRY=https://registry.npmmirror.com \
  -t dshd-linux-test:amd64 -f Dockerfile .
```

x64 dependency installation, the Host/Desktop/Client/Web build gates (10/10),
x64 Electron and the primary runtime all passed. Primary runtime Node/Python
assets default to npmmirror (patch 0003), so nodejs.org/GitHub are not required.
x64 AppImage/deb/rpm/Flatpak were produced. The deb was installed and launched
under amd64 Docker + Xvfb with a working window and local Host. The Flatpak
bundle installed successfully; 25.08 x64 completed GUI startup under Docker +
Xvfb (with a test-only bwrap seccomp bypass; real desktops do not need it).

```bash
pnpm --filter @deepseek-ai/dsh-desktop package:linux:x64
```

x64 Flatpak: 25.08 bundle, 240 MiB, SHA-256 `e3aadf99...` (use
`dist/linux-x64/SHA256SUMS` as the source of truth). Installed ref is
`com.deepseek.harness/x86_64/master`, runtime is
`org.freedesktop.Platform/x86_64/25.08`; installation and GUI evidence is in
[evidence/flatpak-2508-verify.txt](evidence/flatpak-2508-verify.txt). The build
used a host CONNECT proxy to avoid slow Docker NAT downloads.

Repeat the GUI smoke test:

```bash
scripts/smoke-deb-x64.sh
```

It installs the x64 deb, starts Xvfb, launches Electron and writes
`evidence/deb-x64-smoke.png`. See
[evidence/x64-artifacts.txt](evidence/x64-artifacts.txt) and
[evidence/linux-x64-gui.png](evidence/linux-x64-gui.png).

## GUI smoke test

```bash
scripts/smoke-flatpak-x64.sh
```

The script installs the Flatpak bundle, starts Xvfb + dbus, verifies the window
and the `dsh web:` log line, and writes `evidence/flatpak-x64-smoke.png`. It
exists only for Docker testing and is not a distribution patch.

## Rebuild all x64 formats

```bash
scripts/build-flatpak-x64.sh
```

The script starts a CONNECT proxy on the host so Flathub/Electron downloads from
Docker use the host network, then runs `package:linux:x64` and copies
AppImage/deb/rpm/Flatpak + `SHA256SUMS` back to `dist/linux-x64`. It expects the
`dshd-linux-test:flatpak-sdk` image and the `dshd-linux-x64-src` volume to exist.

## Promo video

A 50-second YouTube promo, thumbnail, subtitles and upload copy are in
[`promo/`](promo/README.md); the storyboard and render pipeline are documented
in [`docs/promo.md`](docs/promo.md). The video uses Three.js and deterministic
hyper-frame transitions rather than a screen recording.

## Verification and signing

```bash
gpg --import keys/deepseek-harness-release-signing.asc
scripts/verify-artifacts.sh
DSHD_GPG_KEY=0E6023DF4DB8C68AA2202EF876CE5675AFF067FF scripts/sign-artifacts.sh
```

`SHA256SUMS` and every artifact have detached `.asc` signatures. The public key
fingerprint is `0E6023DF4DB8C68AA2202EF876CE5675AFF067FF`; see
[docs/release-signing.md](docs/release-signing.md). The private key is not in the
repository; replace it with an offline, passphrase-protected key before a
production release. The `unsigned` filename suffix only means there is no
platform code-signing certificate; it does not mean the detached signature is
missing.

## License

Apache-2.0 for this repository. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
Upstream DeepSeek Harness is MIT-licensed; the full upstream notice is in
[LICENSES/MIT-DeepSeek-Harness.txt](LICENSES/MIT-DeepSeek-Harness.txt).
Third-party components, including Electron, the bundled runtime,
LibreOfficeKit WASM and Apache POI test fixtures, remain under their respective
licenses.

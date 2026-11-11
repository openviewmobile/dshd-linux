# Linux architecture

## Scope

A Linux x64/arm64 desktop app that adds Linux build and release targets on top of the official `apps/desktop` (Electron).
It is not a UI rewrite, nor a separate web shell; the goal is to make the official desktop shell
produce installable packages on Linux and pass the Xvfb smoke test.

## Why patches rather than a fork

The official Desktop already ships a linux-x64/linux-arm64 primary runtime (Node 24, Python, pnpm, etc.),
and electron-builder also has a Linux AppImage target; but the release targets list only macOS/Windows, and Linux is
excluded by `desktop-build-paths.mjs` and `package-target.ts`. The project therefore maintains four reviewable patches:

| Patch | Purpose |
|---|---|
| `0001-linux-desktop-target.patch` | Register the Linux target, Electron path, packaging/smoke scripts |
| `0002-linux-deb-rpm-flatpak.patch` | Add deb/rpm/Flatpak targets and Flatpak 25.08 configuration |
| `0004-flatpak-launch.patch` | Flatpak launcher: patch `PATH`, override metadata `command` |
| `0003-primary-runtime-mirrors.patch` | Primary runtime uses npmmirror to reduce dependence on nodejs.org/GitHub |

The patches only change build/release paths; they do not replace the dsh kernel or the frontend.
If upstream moves, the patches may need to be redone.

## Build pipeline

```
Dockerfile (node:24-bookworm + Xvfb + flatpak/rpm)
  └─ /src: upstream deepseek-harness clone
       ├─ git apply patches/
       ├─ pnpm install --frozen-lockfile
       └─ pnpm --filter @deepseek-ai/dsh-desktop package:linux:<arch>
            └─ .desktop-build/targets/linux-<arch>/unsigned-artifacts/
                 AppImage / deb / rpm / flatpak
```

`build-and-smoke.sh` only builds the `--dir` unpacked package and launches it in Xvfb; `package-formats.sh`
produces installable packages; `build-flatpak-x64.sh` rebuilds all x64 formats in a preprovisioned SDK image and fetches the artifacts back into
`dist/linux-x64/`.

## Runtime

- The Electron shell launches the bundled Node's `dsh web`, parses the token URL, and then loads the same dsh Web UI;
- Bundled Node 24 / pnpm / Python / ripgrep; `koffi`, `sharp`, `node-pty`, `grep`, `glob`
  are true in the packaged smoke test;
- On Linux, Electron needs `--no-sandbox` (container tests); official releases configure the sandbox as required;
- Office→PDF uses `@deepseek-ai/libreoffice-kit-wasm` (0.1.5) packaged into the runtime. Linux has no upstream native engine package, so `selectOfficeEngine()` selects WASM; GUI/CLI have been accepted against real conversions, and the Linux skip logic in the packaged smoke test has been removed from the patch (takes effect after the next rebuild).

## Known architecture limitations

- Upstream has no official Linux release acceptance; the patches need to follow upstream changes.
- Auto-update, code signing and notarization are not yet integrated; v1 is unsigned packages + manual/self-hosted updates.
- Wayland, tray, IME and desktop integration have not been systematically verified.

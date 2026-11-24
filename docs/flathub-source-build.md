# Flathub source-build plan

This document records why the current `com.deepseek.harness` Flatpak bundle is
not a Flathub submission and what a real source manifest must build.

## Pinned upstream

- Repository: `https://github.com/deepseek-ai/deepseek-harness`
- Release ref used by DSHD: `fcc0ad462172522aaf5c93a7b2e01f6b9f0b0159`
- Desktop workspace package: `@deepseek-ai/dsh-desktop`
- Runtime pieces: Electron 44, Node 24, Python 3.12, pnpm dependencies

The upstream desktop package builds with:

```bash
pnpm install --frozen-lockfile
pnpm --filter @deepseek-ai/dsh-desktop build
pnpm --filter @deepseek-ai/dsh-desktop prepare:primary-runtime
```

The release pipeline then invokes the `package:linux:x64` / `package:linux:arm64`
electron-builder target. That output is a prebuilt Electron/runtime tree.

## What Flathub requires

Flathub does not accept the electron-builder bundle as an app payload. The
manifest must:

1. Use `org.freedesktop.Platform//25.08` and
   `org.electronjs.Electron2.BaseApp//25.08`.
2. Build the desktop JavaScript bundle from source at a pinned commit.
3. Vendor pnpm/npm packages and any Python dependencies so the build is offline.
4. Provide the Electron/zypak launcher expected by the BaseApp.
5. Install the desktop entry, `com.deepseek.harness.metainfo.xml`, the icon and
   licenses.
6. Pass `flatpak-builder-lint` and a sandboxed launch test.

## Main blockers

- The Electron/Node/Python runtime is currently embedded as a prebuilt payload.
- The pnpm workspace is large and its offline source generation is not yet set up.
- The app's Host is launched with `ELECTRON_RUN_AS_NODE`; the Electron BaseApp
  and runtime layout need an explicit integration test.
- `com.deepseek.harness` is an upstream-looking namespace. Confirm ownership or
  consent before opening the Flathub PR.

## Source-build spike (2026-11-24)

On a Fedora 45 x86_64 host with Node 24 and pnpm 11:

```text
pnpm install --frozen-lockfile: PASS (54 s, about 2.1 GB node_modules)
pnpm run build: PASS (207 s, 10/10 gates)
pnpm --filter @deepseek-ai/dsh-desktop build: PASS (871 ms)
pnpm --filter @deepseek-ai/dsh-desktop prepare:primary-runtime: FAIL
```

After switching the download mirrors, the runtime payload was prepared, but the
next packaging step failed in its Electron runtime smoke test:

```text
runtime payload: pnpm
runtime payload: koffi
runtime payload: sharp
SharpElectronLinux warning
runtime payload: killed=false, signal=SIGSEGV
```

The source build now gets through the monorepo build, desktop bundle, runtime
download and pnpm runtime install. The remaining blocker is the Electron/native
module combination (`sharp`/`koffi`) crashing during the payload smoke test,
plus the offline vendoring required by Flathub.

## AppStream validation

`appstreamcli validate --no-net packaging/appstream/com.deepseek.harness.metainfo.xml`
passes on Fedora 45. This validates the metadata only; it does not make the
draft Flatpak manifest buildable.

## Current decision

Do not submit the bundle or the draft manifest. The repository keeps:

```text
packaging/flathub/com.deepseek.harness.yml        # draft, not buildable
packaging/flathub/com.deepseek.harness.metainfo.xml
packaging/appstream/
```

The next engineering task is to produce an offline, source-built manifest and
run it with `flatpak-builder` before any Flathub PR.

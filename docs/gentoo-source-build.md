# Gentoo source-build option

Status: research / design, 2026-11-13. The supported Gentoo package remains
`deepseek-harness-bin`.

## Why the current package is binary

The upstream Desktop is an Electron application assembled by `pnpm` and
`electron-builder`. Its own packaging documentation only defines macOS, Windows
and an unsigned Linux directory/AppImage path. A source build is therefore not a
simple `./configure && make`:

- the JavaScript/TypeScript monorepo needs Node 24, pnpm 11 and Python;
- `prepare-runtime` downloads an Electron archive through `@electron/get`;
- `prepare-primary-runtime` prepares a bundled Node/Python/pnpm payload;
- `prepare-dsh` installs the runtime with pnpm and materializes native modules;
- `package:linux:*` runs electron-builder and assembles the AppImage.

The binary ebuild avoids all of that by unpacking the signed AppImage.

## Options

| Option | What is built | What is still prebuilt | Assessment |
|---|---|---|---|
| Binary ebuild (current) | Nothing | Electron + primary runtime + app | Reliable and small; not a source build |
| Hybrid source ebuild | JS/TS app, native modules, app layout | Electron archive + Node/Python/pnpm primary runtime | Realistic first source build; overlay/GURU only |
| System-runtime ebuild | App with system Node/Electron | None, if upstream is patched | Requires upstream changes and extensive testing; not compatible with the bundled-runtime design |
| Full source ebuild | Electron/Chromium, Node, Python, pnpm, app | None | Not practical: Electron/Chromium alone is a multi-hour, multi-GB build and Gentoo has no supported generic Electron source package here |

## Recommended first step: hybrid source ebuild

Name it `deepseek-harness-0.2.2_rc1-r3.ebuild`; keep
`deepseek-harness-bin-...` as the binary package. The two must `BLOCK` each
other because both install into `/opt/deepseek-harness`.

### Source and patches

- Fetch a pinned upstream commit/tag (the upstream tag is
  `dsh-v0.2.2-rc.1`, not `v0.2.2-rc.1`).
- Apply this repository's patches `0001`–`0007` in order.
- Use `${PF}` for any local artifact names, as in the binary ebuild.

### Build dependencies

```ebuild
BDEPEND="
    >=net-libs/nodejs-24
    dev-util/pnpm
    dev-lang/python
    app-arch/unzip
"
```

The exact pnpm/Electron/Python versions must be pinned to the upstream
`package.json`/lockfile. A system Node/pnpm may build the app, but the bundled
runtime still expects the upstream primary-runtime versions.

### Offline pnpm store

Gentoo builds must not fetch from the network. Before packaging:

```bash
pnpm fetch --frozen-lockfile
tar -cJf dshd-pnpm-store.tar.xz <pnpm-store-path>
```

Ship that store as a distfile, then build with an offline store:

```bash
pnpm install --frozen-lockfile --offline \
  --store-dir "${WORKDIR}/pnpm-store"
```

The store is large and must be regenerated when the upstream lockfile changes.

### Electron and primary runtime

The cleanest first version ships the exact Electron archive and primary-runtime
payload as checksummed distfiles. This is honest but **still a binary component**;
call it a hybrid build, not a pure source build.

To move toward a true source build, replace those payloads with:

- a source-built Electron/Chromium (not currently realistic), or
- system Electron plus a patched upstream runtime that does not require the
  bundled Node/Python/pnpm and does not call `ELECTRON_RUN_AS_NODE` against its
  own runtime path.

The latter is an upstream design change, not an ebuild-only patch.

### Build and install

A working hybrid command sequence should resemble:

```bash
pnpm install --frozen-lockfile --offline --store-dir "${WORKDIR}/pnpm-store"
pnpm --filter @deepseek-ai/dsh-desktop package:linux:x64:dir
```

Then `src_install()` copies the unpacked directory to `/opt/deepseek-harness`,
installs the wrapper/desktop/icon, and sets `chrome-sandbox` to `4755 root:root`
exactly as the binary ebuild does.

The ebuild still needs to patch or configure the upstream preparation scripts so
they consume the pre-fetched Electron/primary-runtime files instead of calling
`@electron/get` or downloading runtime manifests.

## Policy and acceptance

- A package with prebuilt Electron/runtime is not a pure source package; Gentoo
  main tree is unlikely to accept it. GURU/private overlay is the realistic
  target.
- Keep `RESTRICT="strip"` and `QA_PREBUILT="*"` for the prebuilt payload; a pure
  source build would need a different QA policy.
- The maintainer email in `metadata.xml` must become a real contact before GURU.
- The setuid `chrome-sandbox` needs a written justification in the PR.
- Test at least: `pkgcheck scan`, offline `pnpm install`, directory build,
  `src_install`, `emerge`, launch, and `pnpm`/Python/Office smoke.

## Work estimate

| Work | Estimate |
|---|---|
| Vendor pnpm store and pin sources | 1–2 days |
| Patch preparation scripts for offline Electron/runtime | 2–5 days |
| Ebuild skeleton, install layout and QA | 1–2 days |
| Gentoo test and review fixes | 2–5 days |
| True source Electron/system-runtime path | weeks, upstream-dependent |

## Recommendation

Do not replace the binary ebuild. Add an **experimental hybrid source ebuild** in
the overlay, clearly labeled as hybrid, after the pnpm store and pre-fetched
runtime approach builds and launches. Revisit pure source only if upstream adds
a Linux source-build path that uses system Electron/Node or if a maintainable
Electron source package becomes available.

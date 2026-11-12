# Publishing to Flathub

## Current status

The existing `*.flatpak` file is an electron-builder **bundle**. It can be
installed with `flatpak install --user --bundle`, but it is **not a Flathub
submission**.

Flathub expects an application to be built from a manifest in a sandbox, from
reviewable sources, with no prebuilt application payload. A bundle produced from
a prebuilt Electron/runtime tree is therefore not accepted as-is. Treat current
Flatpak support as “bundle distribution”, not “Flathub publication”.

See the official [Flathub app-author requirements](https://docs.flathub.org/docs/for-app-authors/requirements)
and [submission guide](https://docs.flathub.org/docs/for-app-authors/submission).

## Prerequisites

- Public source repository and an app ID the project controls.
- A source-buildable manifest for the upstream desktop and its runtime.
- Offline dependency sources for pnpm/npm/Python and Electron; Flathub builds
  must not require network access.
- `org.freedesktop.Platform//25.08` and
  `org.electronjs.Electron2.BaseApp//25.08`, plus the Electron/zypak pattern.
- AppStream metadata, icon, screenshots, license and release notes.
- A maintainer who can respond to Flathub review and updates.

## App ID decision

The current package ID is `com.deepseek.harness`. That is an upstream-owned
namespace; an independent repackager should not claim it without permission.
A safer ID is based on the project’s controlled GitHub namespace, for example:

```text
io.github.openviewmobile.dshd
```

Changing the ID affects the desktop file, application data directory, Flatpak
ref, update identity and package metadata. Decide before a stable release.
Flathub also requires the app ID and metadata to match; see the
[app ID guidance](https://docs.flathub.org/docs/for-app-authors/app-id).

## Manifest outline

A source manifest needs, at minimum:

```yaml
app-id: io.github.openviewmobile.dshd
runtime: org.freedesktop.Platform
runtime-version: "25.08"
sdk: org.freedesktop.Sdk
base: org.electronjs.Electron2.BaseApp
base-version: "25.08"
command: dsh-launch

finish-args:
  - --share=ipc
  - --share=network
  - --socket=wayland
  - --socket=fallback-x11
  - --device=dri
  - --socket=pulseaudio
  - --filesystem=home

modules:
  - name: dshd
    buildsystem: simple
    build-commands:
      - install -Dm755 dsh-launch /app/bin/dsh-launch
      # build and install the upstream runtime from vendored sources here
    sources:
      - type: git
        url: https://github.com/deepseek-ai/deepseek-harness.git
        commit: <pinned-commit>
      - type: file
        path: dsh-launch
```

This is only an outline. The real manifest must:

- pin every source and dependency;
- use generated offline sources for pnpm/npm (`flatpak-node-generator` or a
  vendored pnpm store);
- use the Electron BaseApp/zypak strategy accepted by Flathub;
- install the desktop file, metainfo, icon and license;
- pass `flatpak-builder-lint` and a sandboxed launch test.

## Build and test locally

```bash
flatpak install -y flathub org.flatpak.Builder
flatpak run --command=flathub-build org.flatpak.Builder --install manifest.yml
flatpak run io.github.openviewmobile.dshd
flatpak run --command=flatpak-builder-lint org.flatpak.Builder manifest.yml
flatpak run --command=flatpak-builder-lint org.flatpak.Builder repo repo
```

Test a fresh install, first run, real-provider request, Office conversion,
plugin install/remove, X11 and Wayland, and no-network launch behavior.

## Submit

1. Fork `flathub/flathub`.
2. Create a branch from `new-pr`.
3. Add the manifest and metadata.
4. Open a pull request with permission justifications and test evidence.
5. Address the bot/linter/reviewer comments.
6. After merge, users install with:

```bash
flatpak install flathub io.github.openviewmobile.dshd
flatpak run io.github.openviewmobile.dshd
```

Do not open the PR until the manifest builds from source and the app runs in the
sandbox. Submitting the current prebuilt bundle will be rejected and wastes
review capacity.

## Alternative: self-hosted Flatpak repository

If Flathub’s source-build requirements are not feasible yet, a self-hosted
OSTree repository can provide `flatpak install/update` without Flathub:

```bash
flatpak-builder --repo=repo --force-clean build-dir manifest.yml
flatpak build-update-repo repo
# sign repo/ summary and appstream, then host the repo over HTTPS
```

Users add the remote and install:

```bash
flatpak remote-add --if-not-exists dshd https://example.com/dshd.flatpakrepo
flatpak install dshd io.github.openviewmobile.dshd
```

This still requires a source manifest; it is not a shortcut around the
prebuilt-binary problem. GitHub Pages has a 1 GB site limit; a Flatpak OSTree
repository plus multiple versions will exceed it, so plan for object storage or
a dedicated repository/host.

## Effort and sequencing

1. Decide the app ID and trademark position.
2. Build the source manifest and offline dependency set.
3. Pass local build/lint and sandboxed acceptance.
4. Submit to Flathub; expect review iteration.
5. Keep the GitHub Pages/APT/DNF and direct bundle paths working during review.

Realistic effort: several days to a few weeks for the first source manifest,
depending on how much of the upstream Electron/runtime build must be vendored;
Flathub review adds more time.

# AppImage auto-update

The Linux AppImage build now carries an electron-updater generic feed. The
implementation is deliberately separate from the deb/rpm/Flatpak package-manager
channels: only the AppImage self-updates; deb/rpm users continue through APT/DNF
or a new package download.

## Feed layout

Each architecture has a fixed GitHub Release tag:

| Architecture | Feed release | Feed URL |
|---|---|---|
| x86_64 | `appimage-x64-latest` | `https://github.com/openviewmobile/dshd-linux/releases/download/appimage-x64-latest/` |
| aarch64 | `appimage-arm64-latest` | `https://github.com/openviewmobile/dshd-linux/releases/download/appimage-arm64-latest/` |

The feed release contains:

- `latest-linux.yml`
- the current `*-unsigned.AppImage`

`latest-linux.yml` is generated from the AppImage size and SHA-512. The app
bakes the feed URL into `app-update.yml` during packaging.

## Build configuration

`patches/0007-linux-appimage-update.patch` adds `linux-x64`/`linux-arm64` to the
updater target set and accepts `DSHD_APPIMAGE_UPDATE_URL` for Linux. The release
workflow passes the fixed feed URL and `DSH_DESKTOP_UPDATE_CHANNEL=stable` into
the packaging container.

The current UI is the upstream update coordinator: it checks, downloads, asks
for confirmation, and calls `quitAndInstall`. It does not bypass the application
sandbox or install updates silently.

## Publishing the feed

`.github/workflows/appimage-feed.yml` runs after a successful
**Build Linux release assets** run, or manually with a tag. It downloads the
AppImage, writes `latest-linux.yml`, and replaces the assets in the fixed feed
release.

The version in `latest-linux.yml` comes from the release tag (for example
`v0.2.2-rc.2` → `0.2.2-rc.2`). The updater compares this with the installed
version using semver.

## Trust boundaries

- Downloads use HTTPS and the feed's SHA-512, not a platform code-signing
  certificate.
- The feed release is mutable by design: assets are replaced for each release.
  Treat the GitHub repository and its Actions permissions as the trust root.
- Do not use this update channel for a package-manager installation; APT/DNF
  and Flatpak manage their own updates.
- A future production release should add an independent signature or
  attestation to the feed/AppImage, not only HTTPS and SHA-512.

## Test plan

A complete update test needs two versions:

1. Build/install version A with the feed configured.
2. Publish version B with a higher version to the feed.
3. Launch A, let it check, confirm download and install.
4. Verify B starts and the workspace/settings remain intact.
5. Repeat with no network and with a corrupted feed to confirm failure handling.

Until that test is run, the feature should be described as **implemented, pending
version-to-version acceptance**, not as “fully verified”.

## 2026-11-26 acceptance finding

The rc.1.4 AppImage reports:

```text
desktop update: this application has no packaged update source
```

Its extracted `resources/` directory contains no `app-update.yml`. The same is
true of the installed rc.1.5 tree. The cause is in
`apps/desktop/scripts/electron-builder-config.mjs`: `update` was set to
`undefined` whenever `DSH_DESKTOP_UNSIGNED=1`, and the Linux release AppImages
are all built unsigned. The release workflow therefore never enabled the
generic feed for them.

`patches/0009-linux-unsigned-update.patch` keeps the updater config for Linux
when `DSHD_APPIMAGE_UPDATE_URL` is set, while leaving ordinary local unsigned
builds without an update source. A new AppImage pair must be built before the
A→B acceptance can be run; existing rc.1.4/rc.1.5 artifacts cannot self-update.

# Flathub draft

This directory contains the AppStream metadata and a **draft** source manifest
for `io.github.openviewmobile.dshd`.

## Status

The existing `.flatpak` release asset is an electron-builder bundle. It is not
a Flathub submission. Flathub requires a source-built manifest with vendored
dependencies and a pinned upstream commit.

`io.github.openviewmobile.dshd.yml` is therefore a reviewable outline, not a
working build. Do not submit it until the upstream runtime, pnpm/npm/Python
dependencies and Electron/BaseApp integration are fully vendored and the
manifest passes `flatpak-builder-lint`.

## Why the app ID differs

`com.deepseek.harness` is the upstream application namespace. This independent
packaging project uses `io.github.openviewmobile.dshd` for Flathub-facing
metadata to avoid claiming upstream ownership. The current release packages
still use `com.deepseek.harness`; changing the installed app ID is a separate
migration.

## Local validation

```bash
appstreamcli validate io.github.openviewmobile.dshd.metainfo.xml
# once the manifest is real:
flatpak run --command=flatpak-builder-lint org.flatpak.Builder manifest.yml
```

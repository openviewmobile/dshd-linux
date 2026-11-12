# Reddit

Read each subreddit's self-promotion rules first. Disclose that you maintain the
project. Do not paste identical text into several subreddits in one burst.

## r/LocalLLaMA

Title:

```text
I packaged the official DeepSeek Harness Desktop for Linux (AppImage/deb/rpm/Flatpak, ARM64)
```

Body:

```text
The official DSH desktop ships macOS/Windows builds, so Linux users have had to use the web UI or build from source. I made a downstream packaging project for the official Electron desktop.

It includes AppImage, deb, rpm and Flatpak for x86_64 and aarch64, APT/DNF repositories, GPG-signed releases, an SPDX SBOM and GitHub provenance. It also keeps local DOCX/XLSX/PPTX -> PDF working through the bundled WASM engine.

It is an independent project, not an official DeepSeek release, and the desktop/agent core follows upstream.

Current release: https://github.com/openviewmobile/dshd-linux/releases/tag/v0.2.2-rc.1.3

Known gaps: physical Wayland/KDE/GNOME testing is still pending, AppImage auto-update has not completed a version-to-version acceptance, and Flathub/AUR are not published. I would rather get packaging feedback than star counts.
```

## r/linux

Use a technical title, not a marketing one:

```text
Packaging the official DeepSeek Harness Electron desktop for Debian/Fedora/Arch (AppImage, deb, rpm, Flatpak)
```

Body: focus on packaging decisions, `chrome-sandbox`, FUSE, dependency names,
APT/DNF repo layout, and the verification chain. Link the release and ask for
distro-specific testing. If the moderators consider it self-promotion, ask
first rather than reposting.

## r/selfhosted / r/opensource

Lead with local-first/self-hosted and packaging transparency, not model
benchmarks. Do not claim “no telemetry” unless it has been verified in this build.

# Hacker News — Show HN

Post on a weekday morning US Eastern time (about 21:00–23:00 Asia/Shanghai).
Use the GitHub repository as the URL, and put the release link in the body.

## Title

```text
Show HN: DeepSeek Harness Desktop packaged for Linux (signed, apt/dnf)
```

## URL

```text
https://github.com/openviewmobile/dshd-linux
```

## Body

```text
The official DeepSeek Harness desktop publishes macOS and Windows builds, not Linux. I built a downstream Linux packaging project around the official Electron desktop: AppImage, deb, rpm and Flatpak for x86_64 and aarch64, plus static APT/DNF repositories.

It is not another AI client and it does not modify the agent core. The goal is the unglamorous part: make the official desktop installable, updateable and verifiable on Linux.

What is in the release:
- AppImage/deb/rpm/Flatpak for x86_64 and aarch64
- APT and DNF repositories on GitHub Pages (x86_64)
- detached GPG signatures, SHA256SUMS, SPDX SBOM, GitHub build provenance
- local DOCX/XLSX/PPTX -> PDF via bundled WASM
- CI-built and signed releases from GitHub Actions

Known limitations: this is an RC; real Wayland/KDE/GNOME testing is still pending, AppImage auto-update has an implementation but no completed version-to-version acceptance yet, and Flathub/AUR are not published. It is also an independent project, not an official DeepSeek release.

Release: https://github.com/openviewmobile/dshd-linux/releases/tag/v0.2.2-rc.1.3

I would especially value feedback from people who install Linux desktop packages for a living: package naming, sandbox/permission issues, Debian/RPM layout, and whether the apt/dnf repositories are useful.
```

## First comment

```text
Author here. A few details that often come up:

- "unsigned" in the filenames means no platform code-signing certificate; every file has a detached GPG signature and SHA256SUMS.asc.
- The APT/DNF repositories have a real install smoke test in CI, not just metadata checks.
- The desktop runtime is the upstream Electron build; I package it rather than rewriting it in Tauri.
- I am looking for maintainers/reviewers, especially for RPM and Wayland testing.
```

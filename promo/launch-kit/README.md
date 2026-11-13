# DSHD for Linux launch kit

Current release: **v0.2.2-rc.1.3**
Repository: https://github.com/openviewmobile/dshd-linux
Release: https://github.com/openviewmobile/dshd-linux/releases/tag/v0.2.2-rc.1.3

Positioning:

> **DSHD for Linux is a distro-native build of the official DeepSeek Harness
> Desktop: AppImage/deb/rpm/Flatpak, APT/DNF repositories, x86_64 and aarch64,
> signed releases, SBOM/provenance, and local Office→PDF.**

Do not call it official. It is an independent packaging project.

## Assets

- `assets/dshd-linux-demo.gif` — 7-second README/demo animation
- `assets/dshd-linux-promo-1080p.mp4` — 50-second promo
- `assets/dshd-linux-thumbnail.jpg` — video thumbnail
- `assets/dshd-linux-social-preview.jpg` — GitHub/social preview
- `assets/app-chat.png` — real UI screenshot
- `assets/linux-pdf-export.png` — Office→PDF evidence from the earlier rc.1 build (current rc.1.3 does not ship the WASM payload)
- `youtube-metadata.md` — YouTube title/description/tags
- `dshd-linux-promo.en.srt` / `.zh-CN.srt` — captions

## Copy files

- `hacker-news.md`
- `reddit.md`
- `v2ex.md`
- `juejin.md`
- `zhihu.md`
- `x-thread.md`
- `awesome-list.md`

## Recommended order

1. GitHub Release + pinned Discussion (already have the release)
2. DeepSeek/DSH community and awesome list (highest intent)
3. Hacker News Show HN (largest one-shot technical reach)
4. r/LocalLLaMA, r/linux, r/selfhosted, Lobsters
5. V2EX, 掘金, 知乎
6. YouTube walkthrough and long-tail follow-up

Do not post all channels in one hour. Use one primary launch day, then follow up
with technical answers.

## Known limitations to state honestly

- RC, not stable.
- Wayland/KDE/GNOME physical-desktop testing is pending.
- AppImage update feed exists, but version-to-version acceptance is pending.
- Flathub/AUR/Snap/OBS are not published as service builds.
- No platform code-signing certificate; packages use GPG, checksums, SBOM and
  provenance.

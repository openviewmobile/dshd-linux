# Promotion plan

## Positioning

> **DSHD for Linux is the distro-native build of the official DeepSeek Harness
> Desktop: AppImage/deb/rpm/Flatpak, APT/DNF repositories, x86_64 and aarch64,
> signed releases, and local Office→PDF.**

Do not lead with “another AI client”. Lead with the concrete Linux problem:
official desktop packages do not target Linux, and generic AppImage downloads
are hard to manage, verify and update.

## Audience

1. Linux users who already use DeepSeek Harness or want the official desktop
   rather than a web UI.
2. Debian/Ubuntu and Fedora/RHEL users who prefer apt/dnf or Flatpak.
3. ARM64 users (Raspberry Pi, ARM servers, Apple Silicon Linux VMs).
4. Users who cannot install arbitrary AppImages and need signed artifacts and
   checksums.
5. Developers who want local Office conversion and a packaged runtime.

## Proof assets

| Asset | Status |
|---|---|
| 50-second promo video / GIF | Existing |
| Hero screenshot and UI screenshots | Existing, but real GNOME/KDE/Wayland captures are still pending |
| Install command matrix | Existing |
| APT/DNF real-install CI | Existing |
| Released checksums and GPG signatures | Existing |
| SBOM/provenance | Added to next release |
| AppImage auto-update | Implemented; version-to-version acceptance pending |
| Comparison page: native vs Web vs Tauri | Recommended next |

## Pre-launch checklist

- [ ] Publish a clean RC/stable with the production key, SBOM and provenance.
- [ ] Verify every download command from a fresh shell.
- [ ] Verify checksums/signatures and `gh attestation verify`.
- [ ] Add real GNOME/KDE/Wayland screenshots when hardware is available.
- [ ] Confirm README download links point at the latest Release.
- [ ] Confirm “not official” and trademark wording is visible.
- [ ] Pin a welcome Discussion and a support path.
- [ ] Prepare 3–5 good-first issues.
- [ ] Add repository topics: `deepseek`, `deepseek-harness`, `linux`,
  `appimage`, `flatpak`, `deb`, `rpm`, `arm64`, `electron`.
- [ ] Set the GitHub social preview image.
- [ ] Prepare a short press kit: one-liner, 3 screenshots, GIF, logo, links.

## Launch sequence

Do one coordinated launch, not repeated low-effort posts.

### Day 1: GitHub + docs

- Publish the Release with complete notes and verification commands.
- Update README and landing page.
- Post a Discussion: “DSHD 0.2.2: Linux-native packages, apt/dnf, Flatpak,
  signed releases”.

### Day 2: English technical communities

- **Hacker News — Show HN**
  - Title: `Show HN: DeepSeek Harness Desktop packaged for Linux (signed, apt/dnf/Flatpak)`
  - Body: the packaging problem, what is different, what is verified, what is
    not; link to the Release, not a marketing page.
- **Reddit**: r/linux, r/LocalLLaMA, r/selfhosted, r/opensource.
  - Use a technical title and disclose that you maintain the project.
  - Follow each subreddit's self-promotion rules; do not cross-post identical
    text in the same hour.
- **Lobsters**: technical packaging angle.

### Day 3: Chinese communities

- V2EX, 掘金, 知乎.
- Message: “官方 DeepSeek Harness 桌面端没有 Linux 包，我们补了发行版级打包和
  apt/dnf/Flatpak 渠道；不是另一个 AI 客户端。”
- Link to Chinese README and the Release.

### Day 4: DeepSeek ecosystem

- Post in DeepSeek/DSH community spaces and relevant awesome lists.
- Ask for packaging feedback, not stars.

### Week 1: video and follow-up

- Publish the 50-second promo and a 5-minute install/Office walkthrough.
- Reply to every reproducible issue.
- Publish a short “what broke during launch” note; this builds trust.

## Channel-specific copy

### Short English

> DeepSeek Harness Desktop, packaged for Linux. Official Electron shell,
> AppImage/deb/rpm/Flatpak, apt/dnf repos, x86_64 + aarch64, signed releases,
> local Office→PDF. Not an official DeepSeek project.

### Short Chinese

> 给官方 DeepSeek Harness 桌面端补上 Linux 发行版级打包：AppImage / deb / rpm /
> Flatpak，apt/dnf 仓库，x86_64 + aarch64，签名 Release，本地 Office→PDF。
> 不是官方项目，也不魔改 agent。

## What not to do

- Do not claim “official DeepSeek” or imply endorsement.
- Do not claim “verified on every distro” without logs.
- Do not compare by mocking Tauri/other projects.
- Do not post the same link to many subreddits in one burst.
- Do not launch before the download and verification paths are tested.
- Do not hide limitations: Wayland, tray, IME and auto-update acceptance must be
  explicit.

## Metrics

Track weekly:

- Release asset downloads (GitHub API)
- APT/DNF request volume if logs are available
- GitHub stars/forks (secondary)
- Issues opened vs closed and time-to-first-response
- Which distro/format produces the most install failures
- Conversion from landing page to Release download if analytics exist

Do not add telemetry to the app for promotion metrics.

## 30-day calendar

| Week | Work |
|---|---|
| 1 | Release verification, screenshots, press kit, topics/social preview |
| 2 | Show HN, Reddit, Lobsters, Chinese communities |
| 3 | Video walkthrough, DeepSeek ecosystem, follow-up fixes |
| 4 | Retrospective, stable-release decision, Flathub/AUR next step |

## Success criteria

- At least 20 independent install reports across 3+ distros.
- At least 5 reproducible issues with fixes or clear workarounds.
- Download-to-issue ratio is healthy; no major “cannot install” cluster.
- One external contributor or maintainer interested in packaging.
- Stable release decision based on acceptance evidence, not star count.

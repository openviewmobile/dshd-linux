# Competitive landscape and positioning

Snapshot: 2026-11-12. Star counts are approximate and change quickly; use them
for relative context, not as a permanent ranking.

## Direct and adjacent projects

| Project | Approx. stars | What it is | Relationship to DSHD |
|---|---:|---|---|
| [deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness) | 279k | Upstream Harness/desktop source | Upstream; no official Linux release target |
| [anywhere-labs/dsh-desktop](https://github.com/anywhere-labs/dsh-desktop) | 36k | DSH plugin-ecosystem desktop | Adjacent desktop product, much larger community |
| [dataelement/dsh-desktop](https://github.com/dataelement/dsh-desktop) | 18k | DSH desktop app | Adjacent desktop product |
| [dsh-tauri/deepseek-harness-desktop](https://github.com/dsh-tauri/deepseek-harness-desktop) | 3.6k | Tauri desktop alternative, Win/mac/Linux, mobile remote, plugins | Strong product-level alternative; different shell |
| [lencx/Minke](https://github.com/lencx/Minke) | 700 | Local-first DSH desktop workspace | Adjacent polished desktop app |
| [Zhou-Yujing114514/deepseek-harness-linux](https://github.com/Zhou-Yujing114514/deepseek-harness-linux) | 193 | Linux packaging: AppImage/deb/tar.gz, x64/arm64, AppImage auto-update | **Closest direct competitor** |
| [ffyfox/dsh-desktop-linux](https://github.com/ffyfox/dsh-desktop-linux) | 58 | Linux packaging: AppImage/deb/rpm/Arch, upstream patch series | Direct competitor with strong DE test matrix |
| [butterpurse-dot/deepseek-harness-linux](https://github.com/butterpurse-dot/deepseek-harness-linux) | 3 | Community Linux builds with AppImage auto-update | Small, same niche |
| [CherryHQ/cherry-studio](https://github.com/CherryHQ/cherry-studio) | 53k | General AI desktop workspace | Attention competitor, not a DSH repackage |
| [Mintplex-Labs/anything-llm](https://github.com/Mintplex-Labs/anything-llm) | 68k | Local-first AI workspace | Attention competitor |
| [open-webui/open-webui](https://github.com/open-webui/open-webui) | 158k | Web AI interface | Alternative to a native desktop for some users |
| [ollama/ollama](https://github.com/ollama/ollama) | 187k | Local model runtime | Complementary, not a desktop front end |

## What competitors do better

- **Distribution polish:** the closest competitor already has AppImage
  auto-update, a well-known README, search keywords and an explicit
  “what this is / is not” section.
- **Product breadth:** Tauri/DSH desktop projects add remote access, mobile,
  plugin markets, runtime management and richer settings. DSHD is deliberately
  a distribution layer, so it cannot match those features.
- **Desktop verification:** `ffyfox/dsh-desktop-linux` documents real
  KDE/Hyprland/niri/GNOME Wayland tests. DSHD still leans on Xvfb and partial
  Docker evidence.
- **Community:** larger projects have Discord/QQ/WeChat groups, multilingual
  READMEs, docs sites, screenshots/GIFs and visible contributor activity.

## Where DSHD can win

1. **Official Electron shell fidelity.** If the goal is the actual upstream
   desktop (plugins, Host, Office integration), a Tauri rewrite is a different
   product. DSHD should own “the upstream desktop, packaged for Linux”, not
   “another AI client”.
2. **Distro-native distribution.** Signed APT/DNF repositories, Flatpak bundle,
   x86_64/aarch64, and eventually AUR/Arch repository are stronger than a
   release page with three files.
3. **Supply-chain trust.** GPG-signed artifacts/checksums, CI-built releases,
   Pages package repositories and acceptance evidence are differentiators for
   users who cannot install arbitrary AppImages.
4. **Built-in Office→PDF.** The closest packaging competitor explicitly lists
   Office conversion as missing. DSHD’s WASM backend is a concrete feature.
5. **RHEL/Rocky/ARM64.** Enterprise and ARM64 coverage is underserved by
   desktop-first projects.
6. **Bilingual documentation.** English-first with a complete Chinese README;
   many adjacent projects are Chinese-first only.

## Threats

- The direct Linux-packaging competitor can add rpm/Flatpak/Office later.
- The Tauri/desktop products have much larger communities and can absorb the
  “easy Linux install” story with their own installers.
- Upstream may add official Linux targets or a Flathub listing, collapsing the
  packaging niche.
- DeepSeek branding/trademark permission is unresolved; an independent project
  must not imply official endorsement.

## Positioning statement

> **DSHD for Linux is the distro-native distribution of the official DeepSeek
> Harness Desktop: signed AppImage/deb/rpm/Flatpak packages, APT/DNF repositories,
> x86_64 and aarch64, with local Office→PDF.**

Avoid “the best AI desktop”, “official DeepSeek client”, or feature-count
comparisons with Tauri products. Compete on **fidelity, installability, trust,
ARM/enterprise coverage and evidence**.

## Promotion playbook

### 1. Make the first screen sell the result

- One sentence: what it is and who it is for.
- One screenshot/GIF of the actual desktop (chat + local files; Office preview).
- Three direct actions: download, install with apt/dnf, read the docs.
- A visible release status (`rc`, stable) and “not official” disclaimer.

### 2. Show proof, not adjectives

- Add a 30–60 second demo GIF/video to the README.
- Add a verification table: distro, version, X11/Wayland, install result,
  real-provider chat, Office, plugin install.
- Link raw evidence/logs; do not claim “works on X” from metadata alone.
- Publish checksums/signatures and a verification command.

### 3. Reduce time-to-first-run

- Direct per-architecture download links.
- One-line APT/DNF setup.
- First-launch steps with screenshots.
- Troubleshooting for common AppImage/FUSE, sandbox, Wayland and tray issues.
- A single “Which file do I need?” decision table.

### 4. Launch where Linux users look

- Hacker News **Show HN** with a technical angle (“packaging the official DSH
  desktop for Linux, signed, with distro repos”).
- Reddit: r/linux, r/LocalLLaMA, r/selfhosted, r/opensource; follow each
  community’s self-promotion rules.
- Lobsters, V2EX, 掘金/知乎 (Chinese audience), DeepSeek/awesome-dsh community.
- YouTube: 50-second promo plus a 5-minute install/Office walkthrough.
- Distro forums and package-manager communities after APT/DNF/AUR are stable.

### 5. Build a small but real community

- Enable Discussions with categories; seed a welcome post and a “show your
  setup” thread.
- Publish a roadmap with 3–5 concrete items and good-first-issue labels.
- Add Discord/Telegram/QQ/WeChat only when there is capacity to respond.
- Reply to every reproducible bug with status and evidence.

### 6. Release cadence and trust

- Ship a stable `v0.2.2` after the RC acceptance gaps close.
- Keep a public changelog and release notes with tested/untested sections.
- Add AppImage auto-update or a clear update-check UX; apt/dnf users already
  get repository updates.
- Add SBOM/provenance and document key rotation.

### 7. SEO and discovery

- Use the search terms users actually type: “DeepSeek Linux”, “DeepSeek
  desktop Linux”, “DeepSeek AppImage”, “DeepSeek deb”, “DeepSeek rpm”,
  “DeepSeek Flatpak”, “DeepSeek ARM64”.
- Keep GitHub topics and release titles consistent with those terms.
- Publish a docs/landing page with install commands and screenshots; GitHub
  README alone is not a website.
- Add a “Why DSHD?” page comparing native desktop vs Web UI vs Tauri
  alternatives without disparaging competitors.

### 8. Metrics to watch

- Release downloads and APT/DNF request volume (server logs if available).
- GitHub stars/forks are weak signals; prioritize **successful installs,
  repeat visitors, issue resolution time and test coverage**.
- Track which distro/format generates issues; fix the top three.

## Near-term recommendation

1. Add a real demo GIF and KDE/GNOME/Wayland screenshots.
2. Publish the Flathub feasibility plan; do not submit the current prebuilt
   bundle.
3. Ship a stable release and AppImage update path.
4. Run one focused launch (Show HN + one subreddit + one Chinese community)
   after the stable release, not before.
5. Add AUR/Arch repository only after the packaging tests are automated.

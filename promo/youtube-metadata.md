# YouTube upload package

## Video

- File: `out/dshd-linux-promo-1080p.mp4`
- Thumbnail: `out/dshd-linux-thumbnail.jpg`
- GitHub social preview: `out/dshd-linux-social-preview.jpg`
- Captions: `dshd-linux-promo.en.srt`, `dshd-linux-promo.zh-CN.srt`
- Length: 50 seconds, 1920×1080, 30 fps, H.264 + AAC
- Narration: synthesized locally with macOS `say` (Samantha), music generated
  deterministically in `make-audio.py`

## Title (58 characters)

```text
DSHD for Linux — DeepSeek Harness Desktop, native on Linux
```

## Description

```text
DSHD brings DeepSeek Harness Desktop to Linux: real providers, local-first
workspaces, built-in plugins, and Office-to-PDF conversion with a bundled WASM
engine.

This is the 0.2.2-rc.1 release candidate. AppImage, deb, rpm and Flatpak are
available for x86_64 and aarch64. Every artifact has a detached GPG signature
and a signed SHA256SUMS file.

Chapters
00:00 Intro
00:06 A native desktop
00:13 Local-first
00:21 Built-in details
00:28 Office to PDF
00:36 Every Linux package
00:44 Get DSHD

Project and downloads:
https://github.com/openviewmobile/dshd-linux

Verification:
https://github.com/openviewmobile/dshd-linux/blob/main/docs/release-signing.md

Release notes:
https://github.com/openviewmobile/dshd-linux/blob/main/docs/releases/v0.2.2-rc.1.md

Known limits: Snap and OBS packages were built locally but were not installed
from the Snap Store or built on the OBS service. Wayland, tray and IME behavior
have not been verified on physical desktops. The release is GPG-signed, not
platform-code-signed.

Narration is synthesized; the soundtrack is generated for this video.
```

## Tags

```text
DSHD, DeepSeek Harness, DeepSeek Harness Desktop, Linux desktop, Linux app,
AppImage, Flatpak, deb, rpm, AUR, Electron, AI desktop, local-first,
Office to PDF, open source
```

## Settings

- Category: Science & Technology
- Language: English
- Visibility: public after review (use unlisted for the first upload if desired)
- Comments: on
- License: standard YouTube license
- Altered content: yes — synthetic narration and generated music
- End screen: subscribe + link to the GitHub release
- Pin comment: verification instructions and the known-limits section

## Upload checklist

- [ ] Watch the exported 1080p file end to end.
- [ ] Confirm all repository URLs resolve after the release is published.
- [ ] Upload `out/dshd-linux-thumbnail.jpg` and check mobile cropping.
- [ ] Upload the English SRT; add the Chinese SRT as a second subtitle track.
- [ ] Set chapters in the description exactly as above.
- [ ] Add the release link and pin the verification comment.
- [ ] Mark "Altered content" for synthetic narration/music.

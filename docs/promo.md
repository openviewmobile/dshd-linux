# Promotional video

The YouTube package is in [`../promo/`](../promo/README.md). It contains a
50-second, 1920×1080, 30 fps H.264/AAC video, an English and a Chinese subtitle
track, a 1280×720 thumbnail, and copy-ready YouTube metadata.

## Storyboard

| Time | Scene | Message |
|---|---|---|
| 0:00 | Intro | DSHD = DeepSeek Harness Desktop; now native on Linux |
| 0:05 | Desktop | A real Electron workspace, not a browser tab |
| 0:13 | Local-first | Bring your own API key; workspace files stay local |
| 0:21 | Details | Plugins, models, permissions, settings, sessions |
| 0:28 | Office | DOCX/XLSX/PPTX and legacy formats to PDF, on-device |
| 0:36 | Packages | AppImage, deb, rpm, Flatpak; x86_64 and aarch64 |
| 0:44 | CTA | Release candidate; GitHub and signed artifacts |

The narration is deliberately short. The visuals carry the product claims; no
feature is shown that is not backed by evidence in `evidence/`. All in-video
app screenshots are English-only; the Chinese SRT is an optional caption track,
not burned into the picture.

## Render pipeline

- **Three.js** draws the particle field, wireframe floor, orbital rings and
  icosahedron; the camera moves deterministically with the timeline.
- **Hyper-frame transitions**: every cut has a timed gradient wipe plus a soft
  flash, and the scene layers use independent enter/exit curves. Rendering is
  frame-deterministic, not a real-time screen recording.
- **Puppeteer + Chrome** render 1,500 JPEG frames at 30 fps. `render.mjs`
  serves the page locally so ES modules and local assets load without CORS
  exceptions.
- **FFmpeg** encodes H.264 High profile, yuv420p, fast-start, and muxes the AAC
  soundtrack.
- **Audio**: macOS `say` (Samantha) narration, normalized to −16 LUFS; the pad,
  pulse, shimmer and transition risers are synthesized deterministically in
  `make-audio.py`.

## Reproduce

```bash
cd promo
npm install
# macOS: generate the narration stems used by make-audio.py
# (the exact text and starts are in make-audio.py)
python3 make-audio.py
node render.mjs
ffmpeg -framerate 30 -i frames/frame_%05d.jpg \
  -i audio/dshd-linux-promo.m4a \
  -c:v libx264 -preset slow -crf 18 -profile:v high -level 4.2 \
  -pix_fmt yuv420p -movflags +faststart -c:a copy -shortest \
  out/dshd-linux-promo-1080p.mp4
```

The `frames/` directory and WAV/AIFF stems are ignored; the source page,
renderer, audio generator, subtitle files, metadata and final video are kept.
`make-english-assets.py` rebuilds the English screenshot variants if the
original evidence screenshots are restored.

## Accuracy boundaries

- The video says "release candidate", not a stable release.
- Snap and OBS are shown as packaging, not as Store-verified channels; the
  YouTube description repeats that Snap/OBS were not installed from the Store
  or built on the OBS service.
- The video is GPG-signed in the release sense (detached signatures); it is not
  platform-code-signed.
- The CTA says "GitHub · DSHD for Linux"; the upload metadata uses the
  `openviewmobile/dshd-linux` target once the repository is live.

## YouTube

See [`../promo/youtube-metadata.md`](../promo/youtube-metadata.md) for the title,
description, chapters, tags, thumbnail, captions, and upload checklist.

# DSHD for Linux — promo video

A deterministic Three.js / hyper-frame promotional video for the DSHD Linux
release candidate.

## Output

| File | Purpose |
|---|---|
| `out/dshd-linux-promo-1080p.mp4` | 50 s, 1920×1080, 30 fps, H.264/AAC |
| `out/dshd-linux-thumbnail.jpg` | 1280×720 YouTube thumbnail |
| `out/dshd-linux-social-preview.jpg` | 1280×640 GitHub repository social preview |
| `dshd-linux-promo.en.srt` | English captions |
| `dshd-linux-promo.zh-CN.srt` | Chinese captions |
| `youtube-metadata.md` | Title, description, chapters, tags and upload checklist |
| `make-english-assets.py` | Replaces the Chinese sample content in the in-video screenshots with English |

## Build

```bash
npm install
python3 make-audio.py    # macOS `say` + generated music
node render.mjs          # 1,500 deterministic frames + thumbnail
```

The full encode command is in [`../docs/promo.md`](../docs/promo.md).

## Structure

- `index.html` — all scenes, CSS and the Three.js timeline (`window.renderAt(t)`);
- `render.mjs` — local static server, Puppeteer frame capture, thumbnail;
- `make-audio.py` — synthesized score, TTS stem mix and loudness normalization;
- `assets/` — cropped evidence screenshots and brand lockup;
- `frames/`, `audio/*.wav`, `audio/*.aiff` — generated, gitignored.

The video is **not** a screen recording. Every frame is rendered from the same
timeline, so typography, camera motion, wipes and screenshots are repeatable.
The in-video app screenshots are English-only; the Chinese SRT is an optional
caption track and is not burned into the picture.

## Claims and limits

The video is intentionally limited to claims with evidence in `../evidence/`:
real-provider chat, settings/plugins, Office→PDF, the four primary package
formats, both architectures, and detached GPG signatures. Snap/OBS are labeled
as packaging only. The CTA stays generic ("GitHub · DSHD for Linux"); the
upload metadata uses the `openviewmobile/dshd-linux` target.

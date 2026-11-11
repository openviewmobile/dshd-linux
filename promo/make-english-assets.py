#!/usr/bin/env python3
"""Replace the Chinese sample content in the promo screenshots with English.

The UI chrome is already English; only the seeded session title, the demo prompt
and the PDF chat transcript were Chinese. This script edits those regions in
place so the promo never shows Chinese text. Run it from `promo/` after
restoring the original screenshots.
"""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
ASSETS = ROOT / "assets"
FONT = "/System/Library/Fonts/HelveticaNeue.ttc"
INK = (31, 35, 40)
MUTED = (75, 85, 99)
WHITE = (255, 255, 255)
SIDEBAR = (249, 250, 251)
ROW = (237, 239, 241)
BUBBLE = (237, 243, 254)


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT, size, index=1 if bold else 0)


def text(draw: ImageDraw.ImageDraw, xy, value: str, size=14, color=INK, bold=False) -> None:
    draw.text(xy, value, font=font(size, bold), fill=color)


def chat() -> None:
    im = Image.open(ASSETS / "app-chat.png").convert("RGB")
    d = ImageDraw.Draw(im)
    # Session title.
    d.rectangle((300, 38, 500, 66), fill=WHITE)
    text(d, (306, 44), "Provider check", 16, INK, True)
    # Selected workspace row.
    d.rectangle((14, 325, 268, 355), fill=ROW)
    text(d, (35, 332), "Provider check", 14)
    text(d, (245, 337), "now", 11, MUTED)
    # User prompt bubble.
    d.rounded_rectangle((641, 119, 1112, 187), radius=15, fill=BUBBLE)
    text(d, (660, 133), "Reply with only one line: DSHD-LINUX-PROVIDER-OK,", 15)
    text(d, (660, 154), "then write out the result of 17*23.", 15)
    im.save(ASSETS / "app-chat.png", optimize=True)


def settings() -> None:
    im = Image.open(ASSETS / "app-settings.png").convert("RGB")
    d = ImageDraw.Draw(im)
    # The settings dialog dims the sidebar; match the dimmed row colour.
    d.rectangle((14, 325, 238, 355), fill=(189, 190, 191))
    text(d, (40, 332), "Provider check", 14, (75, 77, 80))
    im.save(ASSETS / "app-settings.png", optimize=True)


def pdf() -> None:
    im = Image.open(ASSETS / "app-pdf.png").convert("RGB")
    d = ImageDraw.Draw(im)
    # Session title and selected workspace row.
    d.rectangle((300, 12, 500, 40), fill=WHITE)
    text(d, (306, 16), "Office to PDF", 16, INK, True)
    d.rectangle((14, 294, 268, 323), fill=ROW)
    text(d, (40, 304), "Office to PDF", 14)
    # Report block, including the font-fallback note.
    d.rectangle((302, 64, 674, 270), fill=WHITE)
    text(d, (310, 71), "• Input: input-xlsx.pdf", 14)
    text(d, (310, 95), "• Size: 11,633 bytes · header %PDF-", 14)
    text(d, (310, 119), "• Backend: LibreOffice Kit (wasm)", 14)
    text(d, (310, 143), "  Original source unchanged", 14)
    text(d, (310, 176), "Note: Calibri is missing. Fallback rendering and", 14, MUTED)
    text(d, (310, 200), "pagination may differ slightly from Excel's layout.", 14, MUTED)
    # User prompt bubble.
    d.rounded_rectangle((376, 315, 663, 376), radius=12, fill=BUBBLE)
    text(d, (390, 327), "Use the present tool to show", 14)
    text(d, (390, 349), "/root/input-xlsx.pdf.", 14)
    # Assistant response.
    d.rectangle((302, 470, 674, 527), fill=WHITE)
    text(d, (310, 478), "Presented: input-xlsx.pdf (11,633 bytes).", 14)
    text(d, (310, 500), "Preview it directly in the sidebar.", 14)
    im.save(ASSETS / "app-pdf.png", optimize=True)


if __name__ == "__main__":
    chat()
    settings()
    pdf()
    print("rewrote app-chat.png, app-settings.png and app-pdf.png")

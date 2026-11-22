"""Draws the app's icon (AppIcon) in LaunchControl/Assets.xcassets.

A speedometer in Outrun's colours, its needle on 60: a flat 1024-point square that iOS rounds
itself. Keep the colours in step with Theme.swift's palette.

    python3 make_icons.py   (needs Pillow)
"""
import json
import math
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).parent / "LaunchControl" / "Assets.xcassets"
PRIMARY = "outrun"
SIZE = 2048  # drawn at twice the size, then scaled down to smooth the edges

# background (top, bottom), track, ticks, needle and the arc up to 60, glow
THEMES = {
    "outrun": ((0x0B0221, 0x6B1460), 0x3A1660, 0xF7E8FF, 0xFF2E97, True),
}


def rgb(hex_: int, alpha: int = 255):
    return (hex_ >> 16 & 0xFF, hex_ >> 8 & 0xFF, hex_ & 0xFF, alpha)


def point(c, r, mph):
    """Where a speed sits on the dial: 0-160 over 240 degrees."""
    a = math.radians(210 - 240 * mph / 160)
    return (c + r * math.cos(a), c - r * math.sin(a))


def draw(theme: str) -> Image.Image:
    (top, bottom), track, ticks, accent, glow = THEMES[theme]
    im = Image.new("RGBA", (SIZE, SIZE))
    d = ImageDraw.Draw(im)
    for y in range(SIZE):
        t = y / (SIZE - 1)
        d.line([(0, y), (SIZE, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(rgb(top), rgb(bottom))))

    c, r = SIZE / 2, SIZE * 0.36
    box = [c - r, c - r, c + r, c + r]
    w = round(SIZE * 0.045)
    # PIL's angles run clockwise from 3 o'clock: the dial runs from 150 to 390 (30).
    layer = Image.new("RGBA", im.size)
    ld = ImageDraw.Draw(layer)
    ld.arc(box, 150, 390, fill=rgb(track), width=w)
    ld.arc(box, 150, 240, fill=rgb(accent), width=w)
    for mph in range(0, 161, 20):
        ld.line([point(c, r * 0.86, mph), point(c, r * 0.72, mph)], fill=rgb(accent if mph == 60 else ticks),
                width=round(SIZE * 0.014))
    ld.line([(c, c), point(c, r * 0.9, 60)], fill=rgb(accent), width=round(SIZE * 0.028))
    hub = SIZE * 0.05
    ld.ellipse([c - hub, c - hub, c + hub, c + hub], fill=rgb(accent))

    if glow:
        im.alpha_composite(layer.filter(ImageFilter.GaussianBlur(SIZE * 0.025)))
    im.alpha_composite(layer)
    return im.resize((1024, 1024), Image.LANCZOS)


def write(path: Path, images):
    path.mkdir(parents=True, exist_ok=True)
    (path / "Contents.json").write_text(json.dumps(
        {"images": images, "info": {"author": "xcode", "version": 1}} if images is not None
        else {"info": {"author": "xcode", "version": 1}}, indent=2) + "\n")


def icon(name: str, theme: str):
    path = OUT / f"{name}.appiconset"
    write(path, [{"filename": "icon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}])
    draw(theme).convert("RGB").save(path / "icon.png")


if __name__ == "__main__":
    shutil.rmtree(OUT, ignore_errors=True)
    write(OUT, None)
    icon("AppIcon", PRIMARY)
    print(f"Wrote {OUT}")

"""Draws the app's icons: one per theme, in LaunchControl/Assets.xcassets.

Each is a speedometer in the theme's colours, its needle on 60: a flat 1024-point square that
iOS rounds itself. Outrun's is the app's icon (AppIcon); the others are alternate icons
(AppIcon-<theme>) that ThemeStore switches to, listed in Base.xcconfig. Keep the colours in
step with Theme.swift's palettes.

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
    "lcd": ((0x020605, 0x07120F), 0x0E2620, 0x2B8A6C, 0x4DFFC3, True),
    "gauge": ((0x1E1F23, 0x050506), 0x2A2B30, 0xF2F2F2, 0xFF6A13, False),
    "nightDrive": ((0x000000, 0x000000), 0x1E0505, 0x5E0B0B, 0xC21A1A, False),
    "nixie": ((0x1E140D, 0x0A0604), 0x4A3526, 0xE9C9A6, 0xFFA04A, True),
    "crimson": ((0x8E0E1C, 0x2A0207), 0x4A0610, 0xF4E9EA, 0xE6E9ED, False),
}


def rgb(hex_: int, alpha: int = 255):
    return (hex_ >> 16 & 0xFF, hex_ >> 8 & 0xFF, hex_ & 0xFF, alpha)


def point(c, r, mph):
    """Where a speed sits on the dial: 0-160 over 240 degrees, as in Dial.swift."""
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
    for theme in THEMES:
        if theme != PRIMARY:
            icon(f"AppIcon-{theme}", theme)
    print(f"Wrote {OUT}")

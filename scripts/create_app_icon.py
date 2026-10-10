#!/usr/bin/env python3
"""Regenerate Harbor's original opaque icon. Requires Pillow for development only."""
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
catalog = ROOT / "HarborBrowser" / "Assets.xcassets"
iconset = catalog / "AppIcon.appiconset"
iconset.mkdir(parents=True, exist_ok=True)
scale = 3
size = 1024 * scale
canvas = Image.new("RGB", (size, size))
draw = ImageDraw.Draw(canvas)
for y in range(size):
    t = y / (size - 1)
    color = tuple(round(a + (b - a) * t) for a, b in zip((12, 34, 62), (10, 95, 113)))
    draw.line((0, y, size, y), fill=color)

def polygon(points, fill):
    draw.polygon([(x * scale, y * scale) for x, y in points], fill=fill)

def line(points, fill, width):
    draw.line([(x * scale, y * scale) for x, y in points], fill=fill, width=width * scale, joint="curve")

# Two sails and a small hull, visible at Home Screen size.
polygon([(490, 207), (490, 615), (240, 615)], (244, 250, 251))
polygon([(532, 255), (790, 615), (532, 615)], (95, 224, 205))
line([(514, 194), (514, 654)], (247, 249, 252), 16)
polygon([(220, 649), (813, 649), (747, 730), (293, 730)], (246, 250, 252))
line([(181, 782), (265, 765), (345, 782), (431, 765), (514, 782), (598, 765), (683, 782), (766, 765), (849, 782)], (87, 216, 204), 16)
canvas.resize((1024, 1024), Image.Resampling.LANCZOS).save(iconset / "AppIcon.png")
(catalog / "Contents.json").write_text(json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
(iconset / "Contents.json").write_text(json.dumps({"images": [{"filename": "AppIcon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}], "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
print("Created opaque 1024px AppIcon.png")

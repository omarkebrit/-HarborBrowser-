#!/usr/bin/env python3
"""Render original Aster artwork into the inherited asset identifiers."""

import io
import json
import math
from pathlib import Path

import fitz
from PIL import Image
from reportlab.lib.colors import HexColor
from reportlab.pdfgen import canvas

ROOT = Path(__file__).resolve().parent.parent
SLATE = "#162A34"
SLATE_DEEP = "#10212B"
SAGE = "#B9D4C5"
MIST = "#F1F6F3"
TEAL = "#27675E"


def star(c, x, y, radius, colors):
    c.saveState()
    c.translate(x, y)
    c.scale(radius / 288, radius / 288)
    for index in range(6):
        c.saveState()
        c.rotate(index * 60)
        c.setFillColor(HexColor(colors[index % len(colors)]))
        petal = c.beginPath()
        petal.moveTo(0, 35)
        petal.curveTo(-55, 72, -76, 196, 0, 288)
        petal.curveTo(76, 196, 55, 72, 0, 35)
        c.drawPath(petal, fill=1, stroke=0)
        c.restoreState()
    c.restoreState()


def artwork(width, height, kind="mark", dark=False, tinted=False):
    output = io.BytesIO()
    c = canvas.Canvas(output, pagesize=(width, height), pageCompression=1)
    c.setTitle("Aster original brand artwork")
    c.setAuthor("Aster")
    cx, cy = width / 2, height / 2
    smallest = min(width, height)
    if kind == "icon":
        top = "#314951" if dark else "#284C49"
        bottom = SLATE_DEEP
        if tinted:
            top, bottom = "#3B3F40", "#181B1D"
        c.linearGradient(0, height, width, 0, [HexColor(top), HexColor(bottom)])
        colors = ["#D9E8DD", SAGE] if not tinted else ["#EEEEEE", "#C7CCCC"]
        star(c, cx, cy, smallest * 0.29, colors)
    elif kind == "wordmark":
        c.setFillColor(HexColor("#000000"))
        c.setFont("Helvetica-Bold", height * 0.69)
        label = "Aster"
        label_width = c.stringWidth(label, "Helvetica-Bold", height * 0.69)
        c.drawString((width - label_width) / 2, height * 0.24, label)
    elif kind == "background":
        colors = [SLATE, "#203B3A"] if dark else [MIST, "#DCEAE2"]
        c.linearGradient(0, height, width, 0, [HexColor(color) for color in colors])
    elif kind == "illustration":
        colors = [SAGE, "#D9E8DD"] if dark else [TEAL, "#5B8B76"]
        c.setStrokeColor(HexColor("#688C7E" if dark else "#CEDFD5"))
        c.setLineWidth(max(1, smallest * 0.004))
        c.circle(cx, cy, smallest * 0.40, stroke=1, fill=0)
        c.circle(cx, cy, smallest * 0.33, stroke=1, fill=0)
        star(c, cx, cy, smallest * 0.26, colors)
        c.setFillColor(HexColor(colors[0]))
        for angle, size in [(20, 0.021), (145, 0.014), (255, 0.014)]:
            x = cx + math.cos(math.radians(angle)) * smallest * 0.40
            y = cy + math.sin(math.radians(angle)) * smallest * 0.40
            c.circle(x, y, smallest * size, stroke=0, fill=1)
    else:
        colors = [SAGE] if dark else [TEAL]
        star(c, cx, cy, smallest * 0.44, colors)
    c.showPage()
    c.save()
    return output.getvalue()


def render_png(pdf, width, height, opaque):
    document = fitz.open(stream=pdf, filetype="pdf")
    page = document[0]
    pixmap = page.get_pixmap(matrix=fitz.Matrix(width / page.rect.width, height / page.rect.height), alpha=not opaque)
    image = Image.frombytes("RGBA" if pixmap.alpha else "RGB", (pixmap.width, pixmap.height), pixmap.samples)
    if opaque:
        image = image.convert("RGB")
    output = io.BytesIO()
    image.save(output, format="PNG", optimize=True)
    return output.getvalue()


def replace_file(path, kind, dark=False, tinted=False):
    if path.suffix.lower() == ".pdf":
        document = fitz.open(path)
        size = document[0].rect
        width, height = size.width, size.height
        document.close()
        path.write_bytes(artwork(width, height, kind, dark, tinted))
    elif path.suffix.lower() == ".png":
        with Image.open(path) as image:
            width, height = image.size
        pdf = artwork(width, height, kind, dark, tinted)
        path.write_bytes(render_png(pdf, width, height, opaque=kind == "icon"))
    else:
        raise ValueError(path)


def replace_catalog(catalog):
    count = 0
    for metadata in catalog.rglob("Contents.json"):
        contents = json.loads(metadata.read_text())
        for item in contents.get("images", []):
            if not item.get("filename"):
                continue
            path = metadata.parent / item["filename"]
            appearances = {value["value"] for value in item.get("appearances", [])}
            dark = "dark" in appearances or "dark" in path.stem.lower()
            tinted = "tinted" in appearances or "tinted" in path.stem.lower()
            replace_file(path, "icon", dark=dark, tinted=tinted)
            count += 1
    return count


def replace_imageset(folder, kind):
    metadata = folder / "Contents.json"
    contents = json.loads(metadata.read_text())
    for item in contents.get("images", []):
        if not item.get("filename"):
            continue
        path = folder / item["filename"]
        appearances = {value["value"] for value in item.get("appearances", [])}
        dark = "dark" in appearances or "dark" in path.stem.lower()
        replace_file(path, kind, dark=dark)


def replace_dynamic_mark(folder):
    metadata = folder / "Contents.json"
    contents = json.loads(metadata.read_text())
    old_files = [folder / item["filename"] for item in contents.get("images", []) if item.get("filename")]
    size = fitz.open(old_files[0])[0].rect if old_files and old_files[0].exists() else fitz.Rect(0, 0, 40, 40)
    for path in old_files:
        path.unlink(missing_ok=True)
    for dark, name in [(False, "aster-mark-light.pdf"), (True, "aster-mark-dark.pdf")]:
        (folder / name).write_bytes(artwork(size.width, size.height, dark=dark))
    contents["images"] = [
        {"filename": "aster-mark-light.pdf", "idiom": "universal"},
        {"filename": "aster-mark-dark.pdf", "idiom": "universal", "appearances": [{"appearance": "luminosity", "value": "dark"}]},
    ]
    contents["properties"] = {"preserves-vector-representation": True}
    metadata.write_text(json.dumps(contents, indent=2) + "\n")


def main():
    app_icons = ROOT / "firefox-ios/Client/Assets/AppIcons.xcassets"
    count = replace_catalog(app_icons)
    client_images = ROOT / "firefox-ios/Client/Assets/Images.xcassets"
    kinds = {
        "fxHomeHeaderLogoText": "wordmark", "logoFirefoxLarge": "mark", "splash": "mark",
        "faviconFox": "icon", "foxConfirmation": "illustration", "foxDefaultBrowser": "illustration",
        "foxWithStars": "illustration", "onboardingFoxyWindow": "illustration", "onboardingWelcome": "illustration",
    }
    for folder in client_images.rglob("*.imageset"):
        if folder.stem == "fxHomeHeaderLogoBall":
            replace_dynamic_mark(folder)
        elif folder.stem in kinds:
            replace_imageset(folder, kinds[folder.stem])
    onboarding = ROOT / "BrowserKit/Sources/OnboardingKit/Media.xcassets"
    for folder in onboarding.rglob("*.imageset"):
        if folder.stem == "fxHomeHeaderLogoBall":
            replace_dynamic_mark(folder)
        elif folder.stem == "firefoxLoader":
            replace_imageset(folder, "mark")
        elif "Welcome" in folder.stem or folder.stem in {"onboardingTrackersBrandRefresh", "onboardingSyncWithIconsBrandRefresh"}:
            replace_imageset(folder, "illustration")
        elif folder.stem.startswith("backgroundBrandRefresh"):
            replace_imageset(folder, "background")
    action_icons = ROOT / "firefox-ios/Extensions/ActionExtension/Media.xcassets"
    replace_catalog(action_icons)
    replace_imageset(ROOT / "firefox-ios/Extensions/ShareTo/Images.xcassets/logoFirefoxLarge.imageset", "mark")
    replace_imageset(ROOT / "firefox-ios/CredentialProvider/CredentialAssets.xcassets/logo-glyph.imageset", "mark")
    pdf = artwork(1024, 1024, "icon")
    (ROOT / "branding/aster-app-icon.png").write_bytes(render_png(pdf, 1024, 1024, opaque=True))
    (ROOT / "branding/aster-mark.pdf").write_bytes(artwork(128, 128))
    (ROOT / "branding/aster-wordmark.pdf").write_bytes(artwork(90, 40, "wordmark"))
    print(f"Replaced {count} main/alternate app-icon and preview images with original Aster artwork.")


if __name__ == "__main__":
    main()

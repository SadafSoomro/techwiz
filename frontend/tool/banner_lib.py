"""
FANDOM VERSE - shared banner artwork helpers.

Used by `generate_banner_art.py` to build every bundled banner image
(event category banners + community fandom banners) with Pillow only - no
external assets or network access required.
"""

import math
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

WIDTH, HEIGHT = 1200, 600

FONT_CANDIDATES_BOLD = [
    r"C:\Windows\Fonts\segoeuib.ttf",
    r"C:\Windows\Fonts\arialbd.ttf",
    r"C:\Windows\Fonts\verdanab.ttf",
]

FONT_CANDIDATES_REGULAR = [
    r"C:\Windows\Fonts\segoeui.ttf",
    r"C:\Windows\Fonts\arial.ttf",
    r"C:\Windows\Fonts\verdana.ttf",
]


def load_font(candidates, size):
    """First available TrueType font, falling back to Pillow's default."""
    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                pass
    return ImageFont.load_default()


# ---------------------------------------------------------------------------
# gradients and lighting
# ---------------------------------------------------------------------------
def diagonal_gradient(size, c1, c2, c3):
    """Smooth three stop diagonal gradient.

    The mask is computed at a low resolution and upscaled - a gradient has no
    fine detail, so this is visually identical but ~16x faster.
    """
    w, h = size
    small_w, small_h = max(2, w // 8), max(2, h // 8)

    mask = Image.new("L", (small_w, small_h))
    px = mask.load()

    max_sum = (small_w - 1) + (small_h - 1) or 1
    for y in range(small_h):
        for x in range(small_w):
            px[x, y] = int(((x + y) / max_sum) * 255)

    mask = mask.resize((w, h), Image.BICUBIC)
    return ImageOps.colorize(mask, black=c1, white=c3, mid=c2).convert("RGB")


def radial_glow(base, size, center, radius, strength=120):
    """Adds a soft white radial light to give the banner depth."""
    small = 128
    glow = Image.new("L", (small, small))
    px = glow.load()

    cx = cy = (small - 1) / 2
    for y in range(small):
        for x in range(small):
            d = math.hypot(x - cx, y - cy) / (small / 2)
            px[x, y] = int((max(0.0, 1.0 - d) ** 2) * strength)

    glow = glow.resize(size, Image.BICUBIC)
    light = Image.new("RGB", size, (255, 255, 255))
    return Image.composite(light, base, glow)


def apply_scrim(image, size, max_alpha=205, power=1.5):
    """Darkens the bottom of the banner so overlaid text stays readable."""
    w, h = size
    small_h = max(2, h // 8)

    strip = Image.new("L", (2, small_h))
    px = strip.load()

    for y in range(small_h):
        value = int(max_alpha * (y / (small_h - 1)) ** power)
        px[0, y] = value
        px[1, y] = value

    scrim = strip.resize((w, h), Image.BICUBIC)
    return Image.composite(Image.new("RGB", size, (4, 8, 14)), image, scrim)


# ---------------------------------------------------------------------------
# overlay patterns
# ---------------------------------------------------------------------------
def draw_stripes(size, color=(255, 255, 255), alpha=16, spacing=78, width=3):
    w, h = size
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    x = -h
    while x < w:
        draw.line((x, h, x + h, 0), fill=color + (alpha,), width=width)
        x += spacing

    return overlay


def draw_dot_grid(size, color=(255, 255, 255), alpha=18, spacing=52, radius=2):
    w, h = size
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    for y in range(spacing, h, spacing):
        for x in range(spacing, w, spacing):
            draw.ellipse(
                (x - radius, y - radius, x + radius, y + radius),
                fill=color + (alpha,),
            )

    return overlay


def draw_halftone(size, origin=(0.15, 0.85), color=(255, 255, 255), alpha=40, rings=16, spacing=34):
    """Halftone dots that grow away from the focal point."""
    w, h = size
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    ox, oy = origin[0] * w, origin[1] * h
    max_d = math.hypot(max(ox, w - ox), max(oy, h - oy)) or 1

    for gy in range(int(-h / spacing), int(h * 2 / spacing)):
        for gx in range(int(-w / spacing), int(w * 2 / spacing)):
            x = gx * spacing
            y = gy * spacing
            d = math.hypot(x - ox, y - oy) / max_d
            if d > 1.0:
                continue
            radius = max(0.6, (1.0 - d) * rings * 0.55)
            draw.ellipse(
                (x - radius, y - radius, x + radius, y + radius),
                fill=color + (int(alpha * (1.0 - d)) + 6,),
            )

    return overlay


def draw_speed_lines(size, origin=(0.78, 0.32), color=(255, 255, 255), alpha=34, count=26, inner=120):
    """Radial burst lines - a comic / anime style accent."""
    w, h = size
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    ox, oy = origin[0] * w, origin[1] * h
    length = math.hypot(w, h)

    for i in range(count):
        angle = (2 * math.pi / count) * i + 0.12
        x1 = ox + math.cos(angle) * inner
        y1 = oy + math.sin(angle) * inner
        x2 = ox + math.cos(angle) * length
        y2 = oy + math.sin(angle) * length
        draw.line((x1, y1, x2, y2), fill=color + (alpha,), width=2)

    return overlay


def draw_rings(size, color=(255, 255, 255), center=None, radii=(150, 230, 320, 420), width=3):
    w, h = size
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    cx, cy = center if center else (w - 120, h // 2)

    for i, radius in enumerate(radii):
        draw.ellipse(
            (cx - radius, cy - radius, cx + radius, cy + radius),
            outline=color + (max(12, 46 - i * 10),),
            width=width,
        )

    return overlay


def draw_sparkles(size, points, color=(255, 255, 255), alpha=60):
    w, h = size
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    for (px_, py_, s) in points:
        x, y = px_ * w, py_ * h
        draw.polygon(
            [
                (x, y - s),
                (x + s * 0.34, y - s * 0.34),
                (x + s, y),
                (x + s * 0.34, y + s * 0.34),
                (x, y + s),
                (x - s * 0.34, y + s * 0.34),
                (x - s, y),
                (x - s * 0.34, y - s * 0.34),
            ],
            fill=color + (alpha,),
        )

    return overlay


def draw_crowd_bars(size, color=(255, 255, 255), alpha=22, bar_width=26, gap=16, base_offset=60):
    """Equaliser style bars along the bottom edge."""
    w, h = size
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    x = 40
    index = 0
    while x < w - 40:
        height = 40 + ((index * 37) % 120)
        draw.rounded_rectangle(
            (x, h - base_offset - height, x + bar_width, h - base_offset),
            radius=8,
            fill=color + (alpha,),
        )
        x += bar_width + gap
        index += 1

    return overlay


# ---------------------------------------------------------------------------
# text
# ---------------------------------------------------------------------------
def draw_label_pill(image, text, font, origin=(64, 54), pad=(26, 16)):
    """Rounded translucent pill with the category / fandom name."""
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)

    bbox = draw.textbbox((0, 0), text, font=font)
    text_w, text_h = bbox[2] - bbox[0], bbox[3] - bbox[1]

    pill = (
        origin[0],
        origin[1],
        origin[0] + text_w + pad[0] * 2,
        origin[1] + text_h + pad[1] * 2,
    )

    draw.rounded_rectangle(
        pill,
        radius=(pill[3] - pill[1]) // 2,
        fill=(10, 14, 22, 130),
        outline=(255, 255, 255, 75),
        width=2,
    )
    draw.text(
        (pill[0] + pad[0] - bbox[0], pill[1] + pad[1] - bbox[1]),
        text,
        font=font,
        fill=(255, 255, 255, 238),
    )

    return Image.alpha_composite(image, layer)


def draw_watermark(image, text, font, color=(255, 255, 255, 130), margin=64):
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)

    bbox = draw.textbbox((0, 0), text, font=font)
    draw.text(
        (image.size[0] - margin - (bbox[2] - bbox[0]), image.size[1] - margin),
        text,
        font=font,
        fill=color,
    )

    return Image.alpha_composite(image, layer)


WATERMARK_TEXT = "FANDOM VERSE  ·  POCKET EDITION"


def build_banner(size, title, c1, c2, c3, style="geometric"):
    """Builds one banner image (RGB) with the requested art style."""
    base = diagonal_gradient(size, c1, c2, c3)
    base = radial_glow(base, size, (size[0] * 0.28, size[1] * 0.22), size[0] * 0.7, 120)
    base = apply_scrim(base, size).convert("RGBA")

    if style == "halftone":
        overlay = draw_halftone(size, origin=(0.12, 0.9), alpha=46, rings=18, spacing=32)
        overlay = Image.alpha_composite(overlay, draw_speed_lines(size, alpha=30))
        overlay = Image.alpha_composite(
            overlay, draw_rings(size, center=(size[0] * 0.84, size[1] * 0.3), radii=(90, 150, 220), width=2)
        )
        overlay = Image.alpha_composite(
            overlay,
            draw_sparkles(
                size,
                [(0.2, 0.22, 18), (0.33, 0.68, 12), (0.9, 0.72, 16)],
                alpha=70,
            ),
        )
    else:
        overlay = draw_stripes(size, alpha=16)
        overlay = Image.alpha_composite(overlay, draw_dot_grid(size, alpha=18))
        overlay = Image.alpha_composite(overlay, draw_rings(size))
        overlay = Image.alpha_composite(
            overlay, draw_crowd_bars(size)
        )
        block = Image.new("RGBA", size, (0, 0, 0, 0))
        ImageDraw.Draw(block).rounded_rectangle(
            (-160, size[1] - 200, 340, size[1] + 160),
            radius=90,
            fill=(255, 255, 255, 16),
        )
        overlay = Image.alpha_composite(overlay, block)
        overlay = Image.alpha_composite(
            overlay,
            draw_sparkles(size, [(0.72, 0.26, 26), (0.86, 0.44, 16), (0.62, 0.16, 12)], alpha=60),
        )

    base = Image.alpha_composite(base, overlay.filter(ImageFilter.GaussianBlur(0.4)))

    label_font = load_font(FONT_CANDIDATES_BOLD, 46)
    small_font = load_font(FONT_CANDIDATES_REGULAR, 22)

    base = draw_label_pill(base, title, label_font)
    base = draw_watermark(base, WATERMARK_TEXT, small_font)

    return base.convert("RGB")

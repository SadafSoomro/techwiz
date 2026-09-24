"""
FANDOM VERSE - product artwork helpers (Member 5).

Reuses the shared palette / gradient / pattern helpers from `banner_lib.py`
so the merchandise images blend into exactly the same dark UI as the
Member 3 fandom banners and the Member 4 event banners.

Every product image is a square card-ready illustration built from
Pillow primitives only - no external assets, no network access:

    figures      -> a stylised collectible figure on a pedestal
    shirts       -> a folded-flat t-shirt outline
    collections  -> a stacked box set with a ribbon
    accessories  -> an enamel-pin / ring badge
    digital      -> a device frame with a download + play badge
"""

import math

from PIL import Image, ImageDraw, ImageFilter

from banner_lib import (
    FONT_CANDIDATES_BOLD,
    FONT_CANDIDATES_REGULAR,
    apply_scrim,
    diagonal_gradient,
    draw_dot_grid,
    draw_rings,
    draw_sparkles,
    draw_speed_lines,
    draw_stripes,
    load_font,
)

WATERMARK_TEXT = "FANDOM VERSE  ·  POCKET EDITION"

# Hero area is square - product cards on the Shop Home are square too.
WIDTH, HEIGHT = 800, 800


# ---------------------------------------------------------------------------
# colour helpers
# ---------------------------------------------------------------------------
def shade(rgb, factor):
    """Lightens (factor > 1) or darkens (factor < 1) an RGB triple."""
    return tuple(max(0, min(255, int(channel * factor))) for channel in rgb)


def variant_colors(base, variant):
    """Three-stop gradient derived from a category colour.

    Three variants per category keep neighbouring products visually distinct
    while every product still reads as "belonging" to its category.
    """
    if variant % 3 == 0:
        return shade(base, 1.18), base, shade(base, 0.42)
    if variant % 3 == 1:
        return base, shade(base, 0.62), shade(base, 0.28)
    return shade(base, 1.32), shade(base, 0.78), shade(base, 0.38)


# ---------------------------------------------------------------------------
# silhouette builders - each returns an RGBA layer
# ---------------------------------------------------------------------------
def _shape_layer(size):
    return Image.new("RGBA", size, (0, 0, 0, 0))


def silhouette_figure(size, accent):
    """A collectible figure: pedestal, torso, arms, head and hair spikes."""
    w, h = size
    layer = _shape_layer(size)
    draw = ImageDraw.Draw(layer)

    cx = w * 0.5
    body = (255, 255, 255, 46)
    edge = accent + (150,)

    # ---------- pedestal ----------
    draw.ellipse(
        [cx - w * 0.21, h * 0.735, cx + w * 0.21, h * 0.795],
        fill=(255, 255, 255, 38),
    )
    draw.ellipse(
        [cx - w * 0.17, h * 0.720, cx + w * 0.17, h * 0.768],
        fill=edge,
    )

    # ---------- legs ----------
    draw.rounded_rectangle(
        [cx - w * 0.095, h * 0.575, cx - w * 0.015, h * 0.735],
        radius=int(w * 0.035),
        fill=body,
    )
    draw.rounded_rectangle(
        [cx + w * 0.015, h * 0.575, cx + w * 0.095, h * 0.735],
        radius=int(w * 0.035),
        fill=body,
    )

    # ---------- torso ----------
    draw.rounded_rectangle(
        [cx - w * 0.115, h * 0.375, cx + w * 0.115, h * 0.605],
        radius=int(w * 0.055),
        fill=body,
    )

    # ---------- arms (slightly angled outward) ----------
    draw.rounded_rectangle(
        [cx - w * 0.185, h * 0.395, cx - w * 0.105, h * 0.585],
        radius=int(w * 0.04),
        fill=body,
    )
    draw.rounded_rectangle(
        [cx + w * 0.105, h * 0.395, cx + w * 0.185, h * 0.585],
        radius=int(w * 0.04),
        fill=body,
    )

    # ---------- head ----------
    draw.ellipse(
        [cx - w * 0.095, h * 0.205, cx + w * 0.095, h * 0.395],
        fill=body,
        outline=edge,
        width=max(2, int(w * 0.004)),
    )

    # ---------- hair spikes ----------
    for offset, height in ((-0.075, 0.115), (-0.025, 0.155), (0.030, 0.135), (0.075, 0.095)):
        top = h * (0.205 - height)
        draw.polygon(
            [
                (cx + w * (offset - 0.030), h * 0.245),
                (cx + w * offset, top),
                (cx + w * (offset + 0.030), h * 0.245),
            ],
            fill=edge,
        )

    # ---------- chest emblem ----------
    draw.ellipse(
        [cx - w * 0.035, h * 0.435, cx + w * 0.035, h * 0.505],
        outline=edge,
        width=max(2, int(w * 0.006)),
    )

    # ---------- energy arc behind the figure ----------
    draw.arc(
        [cx - w * 0.33, h * 0.16, cx + w * 0.33, h * 0.90],
        start=205,
        end=335,
        fill=accent + (110,),
        width=max(3, int(w * 0.011)),
    )

    return layer


def silhouette_shirt(size, accent):
    """A flat-lay t-shirt outline with a collar and a printed emblem."""
    w, h = size
    layer = _shape_layer(size)
    draw = ImageDraw.Draw(layer)

    body = (255, 255, 255, 52)
    edge = accent + (165,)
    line = max(3, int(w * 0.007))

    tee = [
        (0.375, 0.250), (0.455, 0.228), (0.545, 0.228), (0.625, 0.250),
        (0.775, 0.360), (0.720, 0.470), (0.660, 0.430),
        (0.685, 0.790), (0.315, 0.790),
        (0.340, 0.430), (0.280, 0.470), (0.225, 0.360),
    ]
    points = [(x * w, y * h) for x, y in tee]

    draw.polygon(points, fill=body, outline=edge)
    draw.line(points + [points[0]], fill=edge, width=line, joint="curve")

    # ---------- collar ----------
    draw.arc(
        [0.435 * w, 0.195 * h, 0.565 * w, 0.300 * h],
        start=0,
        end=180,
        fill=edge,
        width=line,
    )

    # ---------- sleeve hems ----------
    draw.line([(0.720 * w, 0.470 * h), (0.660 * w, 0.430 * h)], fill=edge, width=line)
    draw.line([(0.280 * w, 0.470 * h), (0.340 * w, 0.430 * h)], fill=edge, width=line)

    # ---------- printed emblem ----------
    cx, cy = 0.5 * w, 0.585 * h
    radius = 0.105 * w
    draw.ellipse(
        [cx - radius, cy - radius, cx + radius, cy + radius],
        outline=edge,
        width=line,
    )
    draw.polygon(
        [
            (cx, cy - radius * 0.55),
            (cx + radius * 0.55, cy + radius * 0.45),
            (cx - radius * 0.55, cy + radius * 0.45),
        ],
        outline=edge,
        fill=accent + (70,),
    )

    return layer


def silhouette_collection(size, accent):
    """A box set: three stacked boxes with a ribbon and a lid highlight."""
    w, h = size
    layer = _shape_layer(size)
    draw = ImageDraw.Draw(layer)

    body = (255, 255, 255, 50)
    edge = accent + (168,)
    line = max(3, int(w * 0.007))

    boxes = [
        (0.255, 0.545, 0.745, 0.760),  # bottom
        (0.290, 0.395, 0.710, 0.560),  # middle
        (0.325, 0.245, 0.675, 0.405),  # top
    ]

    for index, (x0, y0, x1, y1) in enumerate(boxes):
        rect = [x0 * w, y0 * h, x1 * w, y1 * h]
        radius = int(w * 0.022)
        draw.rounded_rectangle(
            rect,
            radius=radius,
            fill=shade((255, 255, 255), 1.0) + (44 + index * 6,),
            outline=edge,
            width=line,
        )
        # lid band across the top third of each box
        band = [x0 * w, y0 * h, x1 * w, (y0 + (y1 - y0) * 0.30) * h]
        draw.rounded_rectangle(
            band,
            radius=radius,
            fill=accent + (58,),
            outline=edge,
            width=max(2, line - 1),
        )

    # ---------- ribbon down the middle ----------
    draw.rectangle(
        [0.478 * w, 0.245 * h, 0.522 * w, 0.760 * h],
        fill=accent + (92,),
        outline=edge,
        width=max(2, line - 2),
    )

    # ---------- sparkle on the lid ----------
    sparkle = 0.030 * w
    sx, sy = 0.5 * w, 0.190 * h
    draw.polygon(
        [
            (sx, sy - sparkle * 1.7), (sx + sparkle * 0.5, sy - sparkle * 0.5),
            (sx + sparkle * 1.7, sy), (sx + sparkle * 0.5, sy + sparkle * 0.5),
            (sx, sy + sparkle * 1.7), (sx - sparkle * 0.5, sy + sparkle * 0.5),
            (sx - sparkle * 1.7, sy), (sx - sparkle * 0.5, sy - sparkle * 0.5),
        ],
        fill=edge,
    )

    return layer


def silhouette_accessory(size, accent):
    """An enamel badge: a ring with a keyring loop and a star centre."""
    w, h = size
    layer = _shape_layer(size)
    draw = ImageDraw.Draw(layer)

    body = (255, 255, 255, 44)
    edge = accent + (170,)
    line = max(4, int(w * 0.014))

    cx, cy = 0.5 * w, 0.545 * h
    outer = 0.245 * w

    # ---------- badge disc ----------
    draw.ellipse(
        [cx - outer, cy - outer, cx + outer, cy + outer],
        fill=body,
        outline=edge,
        width=line,
    )
    # inner rim
    inner = outer * 0.74
    draw.ellipse(
        [cx - inner, cy - inner, cx + inner, cy + inner],
        outline=accent + (95,),
        width=max(2, line - 2),
    )

    # ---------- star in the middle ----------
    points = []
    for index in range(10):
        angle = -math.pi / 2 + index * math.pi / 5
        radius = inner * (0.78 if index % 2 == 0 else 0.33)
        points.append((cx + math.cos(angle) * radius, cy + math.sin(angle) * radius))
    draw.polygon(points, fill=accent + (118,), outline=edge)

    # ---------- keyring loop ----------
    loop_r = outer * 0.30
    loop_cx, loop_cy = cx, cy - outer - loop_r * 0.72
    draw.ellipse(
        [loop_cx - loop_r, loop_cy - loop_r, loop_cx + loop_r, loop_cy + loop_r],
        outline=edge,
        width=line,
    )
    draw.line(
        [(loop_cx, loop_cy + loop_r), (cx, cy - outer + line)],
        fill=edge,
        width=max(2, line - 3),
    )

    return layer


def silhouette_digital(size, accent):
    """A device frame with a download arrow and a play badge."""
    w, h = size
    layer = _shape_layer(size)
    draw = ImageDraw.Draw(layer)

    body = (255, 255, 255, 40)
    edge = accent + (172,)
    line = max(3, int(w * 0.008))

    # ---------- device frame ----------
    frame = [0.235 * w, 0.215 * h, 0.765 * w, 0.735 * h]
    draw.rounded_rectangle(
        frame,
        radius=int(w * 0.045),
        fill=body,
        outline=edge,
        width=line,
    )
    # screen inset
    draw.rounded_rectangle(
        [0.275 * w, 0.255 * h, 0.725 * w, 0.695 * h],
        radius=int(w * 0.030),
        outline=accent + (88,),
        width=max(2, line - 2),
    )

    # ---------- download arrow ----------
    cx = 0.5 * w
    draw.line([(cx, 0.335 * h), (cx, 0.500 * h)], fill=edge, width=line + 3)
    draw.polygon(
        [
            (cx - 0.062 * w, 0.485 * h),
            (cx + 0.062 * w, 0.485 * h),
            (cx, 0.580 * h),
        ],
        fill=edge,
    )
    # tray
    draw.line(
        [(0.360 * w, 0.625 * h), (0.360 * w, 0.650 * h)],
        fill=edge,
        width=line,
    )
    draw.line(
        [(0.640 * w, 0.625 * h), (0.640 * w, 0.650 * h)],
        fill=edge,
        width=line,
    )
    draw.line(
        [(0.360 * w, 0.650 * h), (0.640 * w, 0.650 * h)],
        fill=edge,
        width=line,
    )

    # ---------- play badge ----------
    bx, by = 0.700 * w, 0.690 * h
    radius = 0.088 * w
    draw.ellipse(
        [bx - radius, by - radius, bx + radius, by + radius],
        fill=accent + (120,),
        outline=edge,
        width=line,
    )
    draw.polygon(
        [
            (bx - radius * 0.30, by - radius * 0.46),
            (bx + radius * 0.48, by),
            (bx - radius * 0.30, by + radius * 0.46),
        ],
        fill=(255, 255, 255, 235),
    )

    return layer


SILHOUETTES = {
    "figure": silhouette_figure,
    "shirt": silhouette_shirt,
    "collection": silhouette_collection,
    "accessory": silhouette_accessory,
    "digital": silhouette_digital,
}


# ---------------------------------------------------------------------------
# text
# ---------------------------------------------------------------------------
def wrap(text, max_chars):
    """Very small greedy word wrap (product names only, so no edge cases)."""
    words = text.split()
    lines = []
    current = ""

    for word in words:
        candidate = f"{current} {word}".strip()
        if len(candidate) <= max_chars or not current:
            current = candidate
        else:
            lines.append(current)
            current = word

    if current:
        lines.append(current)
    return lines[:2]


def draw_category_pill(image, text, font, origin=(44, 40), pad=(22, 13)):
    """Small translucent pill in the top-left corner."""
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
        fill=(10, 14, 22, 140),
        outline=(255, 255, 255, 78),
        width=2,
    )
    draw.text(
        (pill[0] + pad[0] - bbox[0], pill[1] + pad[1] - bbox[1]),
        text,
        font=font,
        fill=(255, 255, 255, 240),
    )

    return Image.alpha_composite(image, layer)


def draw_name(image, lines, font, margin=44, bottom=64):
    """Bold product name in the bottom-left, with a short accent bar."""
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)

    line_height = int(font.size * 1.18) if hasattr(font, "size") else 44
    total_height = line_height * len(lines)

    start_y = image.size[1] - bottom - total_height

    for index, line in enumerate(lines):
        draw.text(
            (margin, start_y + index * line_height),
            line,
            font=font,
            fill=(255, 255, 255, 245),
        )

    # accent bar above the name
    draw.rounded_rectangle(
        [margin, start_y - 16, margin + 58, start_y - 9],
        radius=4,
        fill=(255, 255, 255, 165),
    )

    return Image.alpha_composite(image, layer)


def draw_watermark(image, text, font, margin=44, color=(255, 255, 255, 120)):
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)

    bbox = draw.textbbox((0, 0), text, font=font)
    draw.text(
        (image.size[0] - margin - (bbox[2] - bbox[0]), image.size[1] - 44),
        text,
        font=font,
        fill=color,
    )

    return Image.alpha_composite(image, layer)


# ---------------------------------------------------------------------------
# main builder
# ---------------------------------------------------------------------------
def build_product(size, name, category, kind, colors):
    """Builds one square product image (RGB)."""
    c1, c2, c3 = colors
    w, h = size
    accent = c2

    # ---------------------------- background ----------------------------
    base = diagonal_gradient(size, c1, c2, c3)
    base = Image.alpha_composite(
        base.convert("RGBA"),
        Image.new("RGBA", size, (0, 0, 0, 0)),
    )
    # radial glow so the figure area lifts off the background
    from banner_lib import radial_glow  # local import keeps the header tidy

    base = radial_glow(base.convert("RGB"), size, (w * 0.5, h * 0.44), w * 0.62, 108)
    base = apply_scrim(base, size, max_alpha=225, power=1.35).convert("RGBA")

    # ---------------------------- patterns ------------------------------
    overlay = draw_stripes(size, alpha=13, spacing=64)
    overlay = Image.alpha_composite(overlay, draw_dot_grid(size, alpha=16, spacing=44))
    overlay = Image.alpha_composite(
        overlay,
        draw_rings(size, center=(w * 0.82, h * 0.20), radii=(70, 120, 180), width=2),
    )
    overlay = Image.alpha_composite(
        overlay, draw_speed_lines(size, origin=(0.14, 0.20), alpha=26, count=20)
    )
    overlay = Image.alpha_composite(
        overlay,
        draw_sparkles(size, [(0.18, 0.30, 16), (0.86, 0.62, 13), (0.74, 0.30, 10)], alpha=58),
    )
    base = Image.alpha_composite(base, overlay.filter(ImageFilter.GaussianBlur(0.4)))

    # --------------------------- silhouette -----------------------------
    builder = SILHOUETTES.get(kind, silhouette_figure)
    shape = builder(size, accent)

    # soft drop shadow behind the silhouette
    shadow = shape.split()[3].filter(ImageFilter.GaussianBlur(18))
    shadow_layer = Image.new("RGBA", size, (3, 6, 12, 0))
    shadow_layer.putalpha(shadow.point(lambda value: int(value * 0.75)))
    base = Image.alpha_composite(base, shadow_layer)

    base = Image.alpha_composite(base, shape)

    # ------------------------------ text --------------------------------
    name_font = load_font(FONT_CANDIDATES_BOLD, 44)
    pill_font = load_font(FONT_CANDIDATES_BOLD, 22)
    small_font = load_font(FONT_CANDIDATES_REGULAR, 19)

    base = draw_name(base, wrap(name.upper(), 18), name_font)
    base = draw_category_pill(base, category.upper(), pill_font)
    base = draw_watermark(base, WATERMARK_TEXT, small_font)

    return base.convert("RGB")

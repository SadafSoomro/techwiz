"""
FANDOM VERSE - banner artwork generator.

Creates every bundled banner image used by the app:

  * frontend/assets/images/events/*.jpg   -> Member 4 event category banners
  * frontend/assets/images/fandoms/*.jpg  -> Member 3 community fandom banners

The palette matches `lib/theme/event_theme.dart` (events) and
`lib/theme/app_theme.dart` (fandoms) so the artwork blends into the dark UI.

Run:  py frontend/tool/generate_banner_art.py
"""

import os

from banner_lib import WIDTH, HEIGHT, build_banner

TOOL_DIR = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.join(os.path.dirname(TOOL_DIR), "assets", "images")

SIZE = (WIDTH, HEIGHT)

# ---------------------------------------------------------------------------
# MEMBER 4 - event category banners  (slug, label, c1, c2, c3)
# ---------------------------------------------------------------------------
EVENT_BANNERS = {
    "fan_convention": ("FAN CONVENTION", (0xF9, 0x73, 0x16), (0xEA, 0x58, 0x0C), (0x7C, 0x2D, 0x12)),
    "cosplay_meetup": ("COSPLAY MEETUP", (0xEC, 0x48, 0x99), (0xDB, 0x27, 0x77), (0x4C, 0x1D, 0x95)),
    "screening": ("SCREENING", (0xF5, 0x9E, 0x0B), (0xD9, 0x77, 0x06), (0x78, 0x35, 0x0F)),
    "gaming_tournament": ("GAMING TOURNAMENT", (0x3B, 0x82, 0xF6), (0x25, 0x63, 0xEB), (0x1E, 0x1B, 0x4B)),
    "comic_con": ("COMIC CON", (0xF4, 0x3F, 0x5E), (0xE1, 0x1D, 0x48), (0x4C, 0x05, 0x19)),
    "concert": ("CONCERT", (0x10, 0xB9, 0x81), (0x05, 0x96, 0x69), (0x06, 0x4E, 0x3B)),
    "fan_meetup": ("FAN MEETUP", (0x8B, 0x5C, 0xF6), (0x7C, 0x3A, 0xED), (0x3B, 0x07, 0x64)),
    "workshop": ("WORKSHOP", (0x06, 0xB6, 0xD4), (0x08, 0x91, 0xB2), (0x0C, 0x4A, 0x6E)),
    "default": ("FANDOM VERSE", (0xF9, 0x73, 0x16), (0xEF, 0x44, 0x44), (0x1E, 0x29, 0x3B)),
}

# ---------------------------------------------------------------------------
# MEMBER 3 - community fandom banners
# ---------------------------------------------------------------------------
FANDOM_BANNERS = {
    "anime": ("ANIME", (0xEC, 0x48, 0x99), (0xDB, 0x27, 0x77), (0x4C, 0x1D, 0x95)),
    "gaming": ("GAMING", (0x3B, 0x82, 0xF6), (0x25, 0x63, 0xEB), (0x1E, 0x1B, 0x4B)),
    "movies_tv": ("MOVIES & TV", (0xF5, 0x9E, 0x0B), (0xD9, 0x77, 0x06), (0x78, 0x35, 0x0F)),
    "comics": ("COMICS", (0xF9, 0x73, 0x16), (0xEA, 0x58, 0x0C), (0x7C, 0x2D, 0x12)),
    "music": ("MUSIC", (0x10, 0xB9, 0x81), (0x05, 0x96, 0x69), (0x06, 0x4E, 0x3B)),
    "sports": ("SPORTS", (0xEF, 0x44, 0x44), (0xDC, 0x26, 0x26), (0x7F, 0x1D, 0x1D)),
    "scifi": ("SCI-FI", (0x8B, 0x5C, 0xF6), (0x7C, 0x3A, 0xED), (0x3B, 0x07, 0x64)),
    "default": ("FANDOM VERSE", (0x7C, 0x3A, 0xED), (0xEC, 0x48, 0x99), (0x1E, 0x29, 0x3B)),
}


def generate(banners, folder, style, label):
    out_dir = os.path.join(ASSETS_DIR, folder)
    os.makedirs(out_dir, exist_ok=True)

    print(f"\n{label} -> {out_dir}")
    for slug, (title, c1, c2, c3) in banners.items():
        image = build_banner(SIZE, title, c1, c2, c3, style=style)
        path = os.path.join(out_dir, f"{slug}.jpg")
        image.save(path, "JPEG", quality=90, optimize=True)
        print(f"  + {os.path.basename(path)}  ({os.path.getsize(path) // 1024} KB)")


def main():
    generate(EVENT_BANNERS, "events", "geometric", "MEMBER 4 - event category banners")
    generate(FANDOM_BANNERS, "fandoms", "halftone", "MEMBER 3 - community fandom banners")
    print("\nDone.")


if __name__ == "__main__":
    main()

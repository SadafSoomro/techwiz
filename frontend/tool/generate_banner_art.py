"""
FANDOM VERSE - banner artwork generator.

Creates every bundled image used by the app:

  * frontend/assets/images/events/*.jpg    -> Member 4 event category banners
  * frontend/assets/images/fandoms/*.jpg   -> Member 3 community fandom banners
                                              (also reused as Member 2 hub covers)
  * frontend/assets/images/content/*.jpg   -> Member 2 news / gallery / video / podcast art
  * frontend/assets/images/avatars/*.jpg   -> Member 1 avatar presets

The palette matches `lib/theme/event_theme.dart` (events), `app_theme.dart`
(fandoms), `content_theme.dart` (Member 2) and `profile_theme.dart` (Member 1)
so the artwork blends into the dark UI.

Run:  py frontend/tool/generate_banner_art.py
"""

import os

from banner_lib import WIDTH, HEIGHT, build_banner, build_tile

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


# ---------------------------------------------------------------------------
# MEMBER 2 / MEMBER 1 - shared palettes (match the Flutter themes)
# ---------------------------------------------------------------------------
PALETTES = {
    "anime": ((0xEC, 0x48, 0x99), (0xDB, 0x27, 0x77), (0x4C, 0x1D, 0x95)),
    "gaming": ((0x3B, 0x82, 0xF6), (0x25, 0x63, 0xEB), (0x1E, 0x1B, 0x4B)),
    "movies": ((0xF5, 0x9E, 0x0B), (0xD9, 0x77, 0x06), (0x78, 0x35, 0x0F)),
    "comics": ((0xF9, 0x73, 0x16), (0xEA, 0x58, 0x0C), (0x7C, 0x2D, 0x12)),
    "music": ((0x10, 0xB9, 0x81), (0x05, 0x96, 0x69), (0x06, 0x4E, 0x3B)),
    "sports": ((0xEF, 0x44, 0x44), (0xDC, 0x26, 0x26), (0x7F, 0x1D, 0x1D)),
    "scifi": ((0x8B, 0x5C, 0xF6), (0x7C, 0x3A, 0xED), (0x3B, 0x07, 0x64)),
    "brand": ((0x22, 0xD3, 0xEE), (0x0E, 0xA5, 0xE9), (0x1E, 0x1B, 0x4B)),
}

# ---------------------------------------------------------------------------
# MEMBER 2 - news thumbnails (label + art)
# ---------------------------------------------------------------------------
NEWS_TILES = [
    ("news_01", "anime", "ONE PIECE · WANO"),
    ("news_02", "gaming", "SPEEDRUN RECORD"),
    ("news_03", "scifi", "SEASON 3 TEASER"),
    ("news_04", "comics", "INDIE AWARD"),
    ("news_05", "music", "WORLD TOUR"),
    ("news_06", "brand", "CYBERPUNK RENEWED"),
    ("news_07", "anime", "BEHIND THE SCENES"),
    ("news_08", "gaming", "PHOTO MODE PATCH"),
]

# ---------------------------------------------------------------------------
# MEMBER 2 - gallery plates (clean, numbered, no label)
# ---------------------------------------------------------------------------
GALLERY_TILES = [
    ("gallery_01", "anime"),
    ("gallery_02", "music"),
    ("gallery_03", "movies"),
    ("gallery_04", "comics"),
    ("gallery_05", "music"),
    ("gallery_06", "gaming"),
    ("gallery_07", "anime"),
    ("gallery_08", "scifi"),
    ("gallery_09", "brand"),
]

# ---------------------------------------------------------------------------
# MEMBER 2 - video stills (letterbox + play mark)
# ---------------------------------------------------------------------------
VIDEO_TILES = [
    ("video_01", "anime"),
    ("video_02", "gaming"),
    ("video_03", "scifi"),
    ("video_04", "music"),
    ("video_05", "gaming"),
    ("video_06", "comics"),
]

# ---------------------------------------------------------------------------
# MEMBER 2 - podcast covers (square, wave art)
# ---------------------------------------------------------------------------
PODCAST_TILES = [
    ("podcast_01", "anime"),
    ("podcast_02", "gaming"),
    ("podcast_03", "movies"),
    ("podcast_04", "music"),
    ("podcast_05", "comics"),
    ("podcast_06", "scifi"),
]

# ---------------------------------------------------------------------------
# MEMBER 1 - avatar presets (square, burst + initial)
# ---------------------------------------------------------------------------
AVATAR_TILES = [
    ("avatar_01", "brand", "A"),
    ("avatar_02", "anime", "K"),
    ("avatar_03", "gaming", "R"),
    ("avatar_04", "movies", "M"),
    ("avatar_05", "music", "S"),
    ("avatar_06", "comics", "D"),
    ("avatar_07", "scifi", "N"),
    ("avatar_08", "sports", "Z"),
]


def _save(image, folder, name, quality=86):
    out_dir = os.path.join(ASSETS_DIR, folder)
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, f"{name}.jpg")
    image.save(path, "JPEG", quality=quality, optimize=True)
    return os.path.getsize(path) // 1024


def generate_content_tiles():
    """Member 2 artwork: news, gallery, video and podcast tiles."""
    print("\nMEMBER 2 - content artwork")

    for name, palette, label in NEWS_TILES:
        kb = _save(build_tile((900, 600), *PALETTES[palette], style="grid", label=label), "content", name)
        print(f"  + {name}.jpg  ({kb} KB)")

    for index, (name, palette) in enumerate(GALLERY_TILES, start=1):
        image = build_tile(
            (800, 800),
            *PALETTES[palette],
            style="frame",
            index=f"{index:02d} / {len(GALLERY_TILES):02d}",
        )
        kb = _save(image, "content", name, quality=84)
        print(f"  + {name}.jpg  ({kb} KB)")

    for name, palette in VIDEO_TILES:
        kb = _save(
            build_tile((960, 540), *PALETTES[palette], style="cinema", play=True),
            "content",
            name,
        )
        print(f"  + {name}.jpg  ({kb} KB)")

    for name, palette in PODCAST_TILES:
        kb = _save(
            build_tile((700, 700), *PALETTES[palette], style="wave", label="PODCAST"),
            "content",
            name,
            quality=84,
        )
        print(f"  + {name}.jpg  ({kb} KB)")


def generate_avatars():
    """Member 1 artwork: avatar presets for the Edit Profile screen."""
    print("\nMEMBER 1 - avatar presets")

    for name, palette, initial in AVATAR_TILES:
        kb = _save(
            build_tile((420, 420), *PALETTES[palette], style="avatar", initial=initial),
            "avatars",
            name,
            quality=86,
        )
        print(f"  + {name}.jpg  ({kb} KB)")


def main():
    generate(EVENT_BANNERS, "events", "geometric", "MEMBER 4 - event category banners")
    generate(FANDOM_BANNERS, "fandoms", "halftone", "MEMBER 3 - community fandom banners")
    generate_content_tiles()
    generate_avatars()
    print("\nDone.")


if __name__ == "__main__":
    main()

"""
FANDOM VERSE - Member 5 product artwork generator.

Creates every bundled image used by the Merchandise Store:

  * frontend/assets/images/products/*.jpg  -> one image per catalogue product
  * frontend/assets/images/shop/*.jpg      -> Shop Home hero + deals banners

The palette is derived from the category colours stored in the
`product_categories` table, so the artwork always matches the app theme.

Run:  py frontend/tool/generate_product_art.py

(The same Pillow helper library also produces the Member 3 fandom banners and
 the Member 4 event banners - see generate_banner_art.py.)
"""

import os

from banner_lib import build_banner
from product_art_lib import WIDTH, HEIGHT, build_product, variant_colors

TOOL_DIR = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.join(os.path.dirname(TOOL_DIR), "assets", "images")

PRODUCT_SIZE = (WIDTH, HEIGHT)
BANNER_SIZE = (1200, 600)

# ---------------------------------------------------------------------------
# category -> (base colour, silhouette kind)
# Must stay in sync with `product_categories.color` / the seeded category names.
# ---------------------------------------------------------------------------
CATEGORIES = {
    "Figures": ((0xF5, 0x9E, 0x0B), "figure"),          # amber
    "Shirts": ((0x8B, 0x5C, 0xF6), "shirt"),            # purple
    "Collections": ((0x06, 0xB6, 0xD4), "collection"),  # cyan
    "Accessories": ((0x10, 0xB9, 0x81), "accessory"),   # emerald
    "Digital Assets": ((0xEC, 0x48, 0x99), "digital"),  # pink
}

# ---------------------------------------------------------------------------
# products - (slug, display name, category)
# The slug must match `products.sku` (upper-cased) / `products.image_url`
# and the order in database/seedShop.js so the variants stay stable.
# ---------------------------------------------------------------------------
PRODUCTS = [
    # ------------------------------ figures ------------------------------
    ("luffy_gear5_figure", "Luffy Gear 5 Figure", "Figures"),
    ("naruto_sage_figure", "Naruto Sage Mode Figure", "Figures"),
    ("tanjiro_kamado_figure", "Tanjiro Kamado Figure", "Figures"),
    ("gojo_satoru_figure", "Gojo Satoru Figure", "Figures"),
    ("goku_ultra_instinct_figure", "Goku Ultra Instinct Figure", "Figures"),
    ("zoro_three_sword_figure", "Roronoa Zoro Figure", "Figures"),
    ("mikasa_ackerman_figure", "Mikasa Ackerman Figure", "Figures"),
    ("nezuko_kamado_figure", "Nezuko Kamado Figure", "Figures"),
    ("sasuke_rinnegan_figure", "Sasuke Rinnegan Figure", "Figures"),

    # ------------------------------- shirts -------------------------------
    ("straw_hat_crew_tee", "Straw Hat Crew Tee", "Shirts"),
    ("konoha_leaf_tee", "Konoha Leaf Village Tee", "Shirts"),
    ("demon_slayer_haori_tee", "Demon Slayer Haori Tee", "Shirts"),
    ("cursed_energy_tee", "Cursed Energy Tee", "Shirts"),
    ("survey_corps_tee", "Survey Corps Tee", "Shirts"),
    ("kpop_lightstick_tee", "K-Pop Lightstick Tee", "Shirts"),

    # ----------------------------- collections -----------------------------
    ("one_piece_collector_box", "One Piece Collector Box", "Collections"),
    ("naruto_legacy_box", "Naruto Legacy Box Set", "Collections"),
    ("demon_slayer_trilogy_box", "Demon Slayer Trilogy Box", "Collections"),
    ("shonen_starter_bundle", "Shonen Starter Bundle", "Collections"),
    ("ghibli_art_collection", "Studio Ghibli Art Collection", "Collections"),

    # ---------------------------- accessories ----------------------------
    ("akatsuki_cloud_ring", "Akatsuki Cloud Ring", "Accessories"),
    ("anime_enamel_pin_set", "Anime Enamel Pin Set", "Accessories"),
    ("straw_hat_keychain", "Straw Hat Keychain", "Accessories"),
    ("gaming_headset_covers", "Fandom Gaming Headset Covers", "Accessories"),
    ("cosplay_wig_care_kit", "Cosplay Wig Care Kit", "Accessories"),

    # --------------------------- digital assets ---------------------------
    ("anime_4k_wallpaper_pack", "Anime 4K Wallpaper Pack", "Digital Assets"),
    ("manga_lettering_font_bundle", "Manga Lettering Font Bundle", "Digital Assets"),
    ("fandom_sfx_sound_pack", "Fandom SFX Sound Pack", "Digital Assets"),
    ("cosplay_pose_reference_pack", "Cosplay Pose Reference Pack", "Digital Assets"),
]

# ---------------------------------------------------------------------------
# Shop Home banners
# ---------------------------------------------------------------------------
SHOP_BANNERS = {
    "shop_hero": ("HANDS UP! FANDOM EXCLUSIVES", (0x7C, 0x3A, 0xED), (0xEC, 0x48, 0x99), (0x1E, 0x1B, 0x4B)),
    "shop_deals": ("DEALS OF THE WEEK", (0xEC, 0x48, 0x99), (0xF9, 0x73, 0x16), (0x4C, 0x05, 0x19)),
    "shop_new": ("NEW ARRIVALS", (0x06, 0xB6, 0xD4), (0x7C, 0x3A, 0xED), (0x0C, 0x4A, 0x6E)),
    "shop_digital": ("DIGITAL ASSETS", (0x10, 0xB9, 0x81), (0x06, 0xB6, 0xD4), (0x06, 0x4E, 0x3B)),
}


def generate_products():
    out_dir = os.path.join(ASSETS_DIR, "products")
    os.makedirs(out_dir, exist_ok=True)

    # one counter per category drives the colour variant
    counters = {}

    print(f"\nMEMBER 5 - product images -> {out_dir}")

    for slug, name, category in PRODUCTS:
        base_color, kind = CATEGORIES[category]
        variant = counters.get(category, 0)
        counters[category] = variant + 1

        image = build_product(
            PRODUCT_SIZE,
            name,
            category,
            kind,
            variant_colors(base_color, variant),
        )
        path = os.path.join(out_dir, f"{slug}.jpg")
        image.save(path, "JPEG", quality=88, optimize=True)
        print(f"  + {os.path.basename(path):<38} ({os.path.getsize(path) // 1024} KB) [{kind}]")


def generate_banners():
    out_dir = os.path.join(ASSETS_DIR, "shop")
    os.makedirs(out_dir, exist_ok=True)

    print(f"\nMEMBER 5 - shop banners -> {out_dir}")

    for slug, (title, c1, c2, c3) in SHOP_BANNERS.items():
        image = build_banner(BANNER_SIZE, title, c1, c2, c3, style="geometric")
        path = os.path.join(out_dir, f"{slug}.jpg")
        image.save(path, "JPEG", quality=90, optimize=True)
        print(f"  + {os.path.basename(path):<38} ({os.path.getsize(path) // 1024} KB)")


def main():
    generate_products()
    generate_banners()
    print("\nDone.")


if __name__ == "__main__":
    main()

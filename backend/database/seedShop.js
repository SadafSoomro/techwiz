/**
 * MEMBER 5 - Merchandise Store + AI Fan Helper
 * Demo data seeder: product categories, the merchandise catalogue, the
 * AI Fan Helper FAQ knowledge base, and (for the demo account) a wishlist,
 * a cart and one simulated past order.
 *
 * Run:  node database/seedShop.js     (or)  npm run seed:shop
 * Safe to run multiple times - existing rows are skipped.
 */

import db from "./db.js";
import { initShopSchema } from "./shopSchema.js";

initShopSchema();

// ---------------------------------------------------------------------------
// helpers
// ---------------------------------------------------------------------------
function run(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) reject(err);
      else resolve(this);
    });
  });
}

function get(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });
}

async function insertIfMissing(table, whereColumn, whereValue, sql, params) {
  const existing = await get(
    `SELECT id FROM ${table} WHERE ${whereColumn} = ?`,
    [whereValue]
  );
  if (existing) return { id: existing.id, created: false };

  const result = await run(sql, params);
  return { id: result.lastID, created: true };
}

// ---------------------------------------------------------------------------
// 1. product categories
// ---------------------------------------------------------------------------
const categories = [
  ["Figures", "figures", "toys_rounded", "#F59E0B", "Collectible figures & statues"],
  ["Shirts", "shirts", "checkroom_rounded", "#8B5CF6", "Official apparel & tees"],
  ["Collections", "collections", "inventory_2_rounded", "#06B6D4", "Box sets & bundles"],
  ["Accessories", "accessories", "watch_rounded", "#10B981", "Pins, keychains & more"],
  ["Digital Assets", "digital-assets", "cloud_download_rounded", "#EC4899", "Wallpapers, fonts & sound packs"],
];

// ---------------------------------------------------------------------------
// 2. products
//    slug -> also the artwork file name (assets/images/products/<slug>.jpg)
//    name, category, fandom, brand, price, oldPrice, stock, rating,
//    ratingCount, soldCount, featured, digital, kind, description
// ---------------------------------------------------------------------------
const products = [
  // ------------------------------ figures ------------------------------
  {
    slug: "luffy_gear5_figure",
    name: "Luffy Gear 5 Figure",
    category: "Figures",
    fandom: "One Piece",
    brand: "Toei Animation Official",
    price: 29.99,
    oldPrice: 44.99,
    stock: 42,
    rating: 4.8,
    ratingCount: 312,
    soldCount: 1284,
    featured: 1,
    kind: "figure",
    description:
      "Hand-finished 25 cm PVC statue of Monkey D. Luffy in his Gear 5 Nika form, with the flowing white hair and drum-of-liberation base. Painted by hand, matte finish, ships in a collector window box.",
  },
  {
    slug: "naruto_sage_figure",
    name: "Naruto Sage Mode Figure",
    category: "Figures",
    fandom: "Naruto",
    brand: "Studio Pierrot Official",
    price: 39.99,
    oldPrice: 49.99,
    stock: 18,
    rating: 4.7,
    ratingCount: 208,
    soldCount: 764,
    featured: 1,
    kind: "figure",
    description:
      "Sage Mode Naruto on a toad-summon base with translucent Rasenshuriken effect parts. 28 cm tall, dynamic mid-air pose, includes a swappable head with closed eyes.",
  },
  {
    slug: "tanjiro_kamado_figure",
    name: "Tanjiro Kamado Figure",
    category: "Figures",
    fandom: "Demon Slayer",
    brand: "Aniplex Official",
    price: 19.99,
    oldPrice: 27.99,
    stock: 0,
    rating: 4.9,
    ratingCount: 421,
    soldCount: 1902,
    featured: 1,
    kind: "figure",
    description:
      "Water Breathing first form Tanjiro with a translucent blue water-slash effect. 24 cm PVC, includes Nichirin blade accessory and a display stand with the Demon Slayer Corps crest.",
  },
  {
    slug: "gojo_satoru_figure",
    name: "Gojo Satoru Figure",
    category: "Figures",
    fandom: "Jujutsu Kaisen",
    brand: "MAPPA Official",
    price: 34.99,
    oldPrice: null,
    stock: 27,
    rating: 4.9,
    ratingCount: 356,
    soldCount: 1104,
    featured: 0,
    kind: "figure",
    description:
      "Gojo removing his blindfold, mid-Domain Expansion. Includes translucent Infinity effect ring and removable sunglasses. 26 cm, limited first-run paint variant.",
  },
  {
    slug: "goku_ultra_instinct_figure",
    name: "Goku Ultra Instinct Figure",
    category: "Figures",
    fandom: "Dragon Ball",
    brand: "Toei Animation Official",
    price: 42.99,
    oldPrice: 54.99,
    stock: 12,
    rating: 4.6,
    ratingCount: 187,
    soldCount: 592,
    featured: 1,
    kind: "figure",
    description:
      "Ultra Instinct Sign Goku with a metallic silver hair deco and cracked-arena base. 30 cm, the largest figure in the Fandom Verse range, with an LED-ready base socket.",
  },
  {
    slug: "zoro_three_sword_figure",
    name: "Roronoa Zoro Figure",
    category: "Figures",
    fandom: "One Piece",
    brand: "Toei Animation Official",
    price: 27.99,
    oldPrice: null,
    stock: 33,
    rating: 4.7,
    ratingCount: 241,
    soldCount: 878,
    featured: 0,
    kind: "figure",
    description:
      "Three-sword style Zoro in his post-timeskip outfit with scar detail. 25 cm, includes two loose katana accessories that slot into the belt.",
  },
  {
    slug: "mikasa_ackerman_figure",
    name: "Mikasa Ackerman Figure",
    category: "Figures",
    fandom: "Attack on Titan",
    brand: "Kodansha Official",
    price: 31.99,
    oldPrice: 39.99,
    stock: 9,
    rating: 4.5,
    ratingCount: 132,
    soldCount: 405,
    featured: 0,
    kind: "figure",
    description:
      "Mikasa with dual blades and ODM gear harness, on a rooftop diorama base. 24 cm, hand-painted cloth-look cape and a detachable scarf.",
  },
  {
    slug: "nezuko_kamado_figure",
    name: "Nezuko Kamado Figure",
    category: "Figures",
    fandom: "Demon Slayer",
    brand: "Aniplex Official",
    price: 19.99,
    oldPrice: 24.99,
    stock: 51,
    rating: 4.8,
    ratingCount: 298,
    soldCount: 1436,
    featured: 0,
    kind: "figure",
    description:
      "Nezuko in her bamboo-muzzle form with a soft pink hair gradient. 22 cm PVC with a cute chibi proportion and a display base shaped like a wisteria branch.",
  },
  {
    slug: "sasuke_rinnegan_figure",
    name: "Sasuke Rinnegan Figure",
    category: "Figures",
    fandom: "Naruto",
    brand: "Studio Pierrot Official",
    price: 36.99,
    oldPrice: null,
    stock: 15,
    rating: 4.6,
    ratingCount: 164,
    soldCount: 512,
    featured: 0,
    kind: "figure",
    description:
      "Blank-period Sasuke with the Rinnegan and Sharingan printed on swappable face plates. 27 cm, includes a sword-sheath accessory and a lightning effect part.",
  },

  // ------------------------------- shirts -------------------------------
  {
    slug: "straw_hat_crew_tee",
    name: "Straw Hat Crew Tee",
    category: "Shirts",
    fandom: "One Piece",
    brand: "Fandom Verse Atelier",
    price: 24.99,
    oldPrice: 32.99,
    stock: 120,
    rating: 4.7,
    ratingCount: 412,
    soldCount: 1873,
    featured: 1,
    kind: "shirt",
    description:
      "Heavyweight 240 GSM combed cotton tee with a screen-printed Jolly Roger on the chest and the crew roster on the back. Pre-shrunk, unisex fit, sizes S to 3XL.",
  },
  {
    slug: "konoha_leaf_tee",
    name: "Konoha Leaf Village Tee",
    category: "Shirts",
    fandom: "Naruto",
    brand: "Fandom Verse Atelier",
    price: 22.99,
    oldPrice: null,
    stock: 98,
    rating: 4.6,
    ratingCount: 287,
    soldCount: 1204,
    featured: 0,
    kind: "shirt",
    description:
      "Leaf Village symbol in a distressed vintage print on an oversized boxy tee. 220 GSM cotton, enzyme-washed for a soft worn-in feel.",
  },
  {
    slug: "demon_slayer_haori_tee",
    name: "Demon Slayer Haori Tee",
    category: "Shirts",
    fandom: "Demon Slayer",
    brand: "Fandom Verse Atelier",
    price: 26.99,
    oldPrice: 34.99,
    stock: 76,
    rating: 4.8,
    ratingCount: 331,
    soldCount: 986,
    featured: 1,
    kind: "shirt",
    description:
      "All-over haori check pattern tee inspired by Tanjiro's cloak, with a woven Corps patch on the sleeve. 240 GSM cotton, regular fit.",
  },
  {
    slug: "cursed_energy_tee",
    name: "Cursed Energy Tee",
    category: "Shirts",
    fandom: "Jujutsu Kaisen",
    brand: "Fandom Verse Atelier",
    price: 23.99,
    oldPrice: null,
    stock: 88,
    rating: 4.5,
    ratingCount: 196,
    soldCount: 742,
    featured: 0,
    kind: "shirt",
    description:
      "Glow-in-the-dark cursed energy swirl with the Tokyo Jujutsu High emblem on the back. 230 GSM cotton, charge it under light for a night-time glow.",
  },
  {
    slug: "survey_corps_tee",
    name: "Survey Corps Tee",
    category: "Shirts",
    fandom: "Attack on Titan",
    brand: "Fandom Verse Atelier",
    price: 25.99,
    oldPrice: 31.99,
    stock: 64,
    rating: 4.6,
    ratingCount: 224,
    soldCount: 811,
    featured: 0,
    kind: "shirt",
    description:
      "Wings of Freedom emblem printed large across the back, with a small Scout crest on the left chest. 240 GSM cotton, unisex fit.",
  },
  {
    slug: "kpop_lightstick_tee",
    name: "K-Pop Lightstick Tee",
    category: "Shirts",
    fandom: "K-Pop",
    brand: "Fandom Verse Atelier",
    price: 21.99,
    oldPrice: 28.99,
    stock: 140,
    rating: 4.4,
    ratingCount: 158,
    soldCount: 903,
    featured: 0,
    kind: "shirt",
    description:
      "Cropped-fit tee with a neon lightstick graphic and reflective ink accents. 200 GSM cotton, designed for concert nights.",
  },

  // ----------------------------- collections -----------------------------
  {
    slug: "one_piece_collector_box",
    name: "One Piece Collector Box",
    category: "Collections",
    fandom: "One Piece",
    brand: "Fandom Verse Vault",
    price: 89.99,
    oldPrice: 119.99,
    stock: 14,
    rating: 4.9,
    ratingCount: 176,
    soldCount: 342,
    featured: 1,
    kind: "collection",
    description:
      "Limited run of 500 boxes: Luffy Gear 5 figure, a Wanted-poster art print set, a Going Merry enamel pin and a numbered authenticity card. Ships in a magnetic-lid display box.",
  },
  {
    slug: "naruto_legacy_box",
    name: "Naruto Legacy Box Set",
    category: "Collections",
    fandom: "Naruto",
    brand: "Fandom Verse Vault",
    price: 79.99,
    oldPrice: null,
    stock: 21,
    rating: 4.8,
    ratingCount: 143,
    soldCount: 288,
    featured: 0,
    kind: "collection",
    description:
      "Three eras of Naruto in one set: kid, Shippuden and Hokage mini-figures, a scroll-shaped art book and a Hidden Leaf headband with machine-embroidered metal plate.",
  },
  {
    slug: "demon_slayer_trilogy_box",
    name: "Demon Slayer Trilogy Box",
    category: "Collections",
    fandom: "Demon Slayer",
    brand: "Fandom Verse Vault",
    price: 74.99,
    oldPrice: 94.99,
    stock: 17,
    rating: 4.7,
    ratingCount: 129,
    soldCount: 251,
    featured: 0,
    kind: "collection",
    description:
      "Tanjiro, Zenitsu and Inosuke figures with a fold-out Infinity Castle backdrop and three breathing-technique effect parts. Presentation boxed.",
  },
  {
    slug: "shonen_starter_bundle",
    name: "Shonen Starter Bundle",
    category: "Collections",
    fandom: "Shonen",
    brand: "Fandom Verse Vault",
    price: 59.99,
    oldPrice: 79.99,
    stock: 30,
    rating: 4.6,
    ratingCount: 211,
    soldCount: 617,
    featured: 0,
    kind: "collection",
    description:
      "The perfect first order: two mini-figures, a sticker sheet, an enamel pin and a poster tube with four A3 art prints from four different shonen series.",
  },
  {
    slug: "ghibli_art_collection",
    name: "Studio Ghibli Art Collection",
    category: "Collections",
    fandom: "Studio Ghibli",
    brand: "Fandom Verse Vault",
    price: 64.99,
    oldPrice: null,
    stock: 11,
    rating: 4.9,
    ratingCount: 268,
    soldCount: 470,
    featured: 1,
    kind: "collection",
    description:
      "Six giclée art prints on textured cotton paper with a numbered certificate, presented in a cloth-bound portfolio case. Frame-ready sizes.",
  },

  // ---------------------------- accessories ----------------------------
  {
    slug: "akatsuki_cloud_ring",
    name: "Akatsuki Cloud Ring",
    category: "Accessories",
    fandom: "Naruto",
    brand: "Fandom Verse Atelier",
    price: 14.99,
    oldPrice: 19.99,
    stock: 210,
    rating: 4.5,
    ratingCount: 302,
    soldCount: 1618,
    featured: 0,
    kind: "accessory",
    description:
      "Stainless steel signet ring with the red Akatsuki cloud inlay and the organisation's scratch-mark engraved on the inner band. Adjustable band, tarnish resistant.",
  },
  {
    slug: "anime_enamel_pin_set",
    name: "Anime Enamel Pin Set",
    category: "Accessories",
    fandom: "Multi-Fandom",
    brand: "Fandom Verse Atelier",
    price: 17.99,
    oldPrice: null,
    stock: 156,
    rating: 4.7,
    ratingCount: 189,
    soldCount: 734,
    featured: 0,
    kind: "accessory",
    description:
      "Set of five hard-enamel pins with gold-plated edges and double rubber clutches. Includes a felt backing card, ready to gift.",
  },
  {
    slug: "straw_hat_keychain",
    name: "Straw Hat Keychain",
    category: "Accessories",
    fandom: "One Piece",
    brand: "Toei Animation Official",
    price: 9.99,
    oldPrice: 13.99,
    stock: 320,
    rating: 4.6,
    ratingCount: 411,
    soldCount: 2380,
    featured: 1,
    kind: "accessory",
    description:
      "Soft-touch PVC straw hat charm with a woven ribbon and a lobster-claw clip. Attach it to a bag, keys or a lanyard.",
  },
  {
    slug: "gaming_headset_covers",
    name: "Fandom Gaming Headset Covers",
    category: "Accessories",
    fandom: "Gaming",
    brand: "Fandom Verse Tech",
    price: 19.99,
    oldPrice: null,
    stock: 74,
    rating: 4.4,
    ratingCount: 96,
    soldCount: 318,
    featured: 0,
    kind: "accessory",
    description:
      "Stretch-fit fabric covers for 9-11 cm headset ear cups with a printed fandom motif. Machine washable, sold as a pair.",
  },
  {
    slug: "cosplay_wig_care_kit",
    name: "Cosplay Wig Care Kit",
    category: "Accessories",
    fandom: "Cosplay",
    brand: "Fandom Verse Atelier",
    price: 29.99,
    oldPrice: 38.99,
    stock: 46,
    rating: 4.8,
    ratingCount: 137,
    soldCount: 402,
    featured: 0,
    kind: "accessory",
    description:
      "Everything a cosplayer needs between conventions: a detangling brush, wig shampoo, setting spray, a wide-tooth comb and a travel garment bag.",
  },

  // --------------------------- digital assets ---------------------------
  {
    slug: "anime_4k_wallpaper_pack",
    name: "Anime 4K Wallpaper Pack",
    category: "Digital Assets",
    fandom: "Multi-Fandom",
    brand: "Fandom Verse Digital",
    price: 4.99,
    oldPrice: 9.99,
    stock: 9999,
    rating: 4.7,
    ratingCount: 523,
    soldCount: 3120,
    featured: 1,
    digital: 1,
    kind: "digital",
    description:
      "60 original 4K (3840x2160) wallpapers in phone, desktop and ultrawide crops. Instant download link after checkout, royalty-free for personal use.",
  },
  {
    slug: "manga_lettering_font_bundle",
    name: "Manga Lettering Font Bundle",
    category: "Digital Assets",
    fandom: "Manga",
    brand: "Fandom Verse Digital",
    price: 12.99,
    oldPrice: 19.99,
    stock: 9999,
    rating: 4.6,
    ratingCount: 214,
    soldCount: 986,
    featured: 0,
    digital: 1,
    kind: "digital",
    description:
      "Eight comic lettering fonts (SFX, dialogue, caption and title styles) with OTFs, a usage guide and editable layered templates for Krita and Photoshop.",
  },
  {
    slug: "fandom_sfx_sound_pack",
    name: "Fandom SFX Sound Pack",
    category: "Digital Assets",
    fandom: "Multi-Fandom",
    brand: "Fandom Verse Digital",
    price: 7.99,
    oldPrice: null,
    stock: 9999,
    rating: 4.5,
    ratingCount: 168,
    soldCount: 641,
    featured: 0,
    digital: 1,
    kind: "digital",
    description:
      "120 royalty-free sound effects for edits and fan videos: whooshes, energy bursts, sword clashes, crowd reactions and notification chimes, all 48 kHz WAV.",
  },
  {
    slug: "cosplay_pose_reference_pack",
    name: "Cosplay Pose Reference Pack",
    category: "Digital Assets",
    fandom: "Cosplay",
    brand: "Fandom Verse Digital",
    price: 6.99,
    oldPrice: 11.99,
    stock: 9999,
    rating: 4.8,
    ratingCount: 302,
    soldCount: 1147,
    featured: 0,
    digital: 1,
    kind: "digital",
    description:
      "300 photographed action poses with lighting notes, plus silhouette overlays to plan dynamic cosplay shots. Delivered as a PDF plus PNG bundle.",
  },
];

// ---------------------------------------------------------------------------
// 3. AI Fan Helper knowledge base (the "predefined fandom FAQs")
// ---------------------------------------------------------------------------
const faqs = [
  {
    question: "Who is Luffy?",
    answer:
      "Monkey D. Luffy is the main protagonist of the anime and manga series One Piece. He is the founder and captain of the Straw Hat Pirates, and his dream is to find the legendary treasure known as the One Piece and become the King of the Pirates. He ate the Gum-Gum Fruit, which turned his body into rubber - and in the Wano arc that awakening was revealed as the Human-Human Fruit, Model: Nika, giving him the Gear 5 form.",
    keywords: "luffy,monkey d luffy,one piece,straw hat,captain,nika,gear 5,gum gum",
    topic: "One Piece",
    imageUrl: "assets/images/products/luffy_gear5_figure.jpg",
  },
  {
    question: "Who is Naruto Uzumaki?",
    answer:
      "Naruto Uzumaki is the title character of Naruto and Naruto Shippuden. He is a jinchuriki who hosts the Nine-Tailed Fox, Kurama, and he goes from being the village outcast to the Seventh Hokage of the Hidden Leaf Village. His signature moves are the Shadow Clone Jutsu and the Rasengan.",
    keywords: "naruto,uzumaki,nine tails,kurama,hokage,rasengan,shadow clone",
    topic: "Naruto",
    imageUrl: "assets/images/products/naruto_sage_figure.jpg",
  },
  {
    question: "Who is Tanjiro Kamado?",
    answer:
      "Tanjiro Kamado is the protagonist of Demon Slayer: Kimetsu no Yaiba. After his family is slaughtered and his sister Nezuko is turned into a demon, he joins the Demon Slayer Corps to find a cure for her. He practises Water Breathing and later Sun Breathing, and his strongest trait is his extraordinary sense of smell.",
    keywords: "tanjiro,kamado,demon slayer,kimetsu no yaiba,nezuko,water breathing,sun breathing",
    topic: "Demon Slayer",
    imageUrl: "assets/images/products/tanjiro_kamado_figure.jpg",
  },
  {
    question: "Who is Gojo Satoru?",
    answer:
      "Satoru Gojo is a special-grade jujutsu sorcerer and a teacher at Tokyo Jujutsu High in Jujutsu Kaisen. He inherited both the Limitless technique and the Six Eyes, which makes him widely considered the strongest sorcerer alive. His Domain Expansion is called Unlimited Void.",
    keywords: "gojo,satoru,jujutsu kaisen,limitless,six eyes,domain expansion,unlimited void",
    topic: "Jujutsu Kaisen",
    imageUrl: "assets/images/products/gojo_satoru_figure.jpg",
  },
  {
    question: "What is Attack on Titan about?",
    answer:
      "Attack on Titan follows Eren Yeager and the Survey Corps as humanity fights for survival behind enormous walls against man-eating Titans. What begins as a survival story gradually reveals a far deeper political and historical conflict. Main characters include Eren, Mikasa Ackerman and Armin Arlert.",
    keywords: "attack on titan,aot,eren,mikasa,armin,survey corps,titan,shingeki",
    topic: "Attack on Titan",
    imageUrl: "assets/images/products/mikasa_ackerman_figure.jpg",
  },
  {
    question: "Who is Son Goku?",
    answer:
      "Son Goku is the main character of Dragon Ball. He is a Saiyan warrior sent to Earth as a baby who grows into its greatest defender. He is known for the Kamehameha wave and for repeatedly pushing past his limits - Super Saiyan, Super Saiyan Blue and Ultra Instinct are his most famous transformations.",
    keywords: "goku,dragon ball,saiyan,kamehameha,super saiyan,ultra instinct,vegeta",
    topic: "Dragon Ball",
    imageUrl: "assets/images/products/goku_ultra_instinct_figure.jpg",
  },
  {
    question: "How do I care for my figure?",
    answer:
      "Keep your figure out of direct sunlight and away from heat - UV light fades paint and warps PVC. Dust it with a soft makeup or camera brush and never use alcohol or acetone wipes. For stubborn marks, use a slightly damp microfibre cloth with a drop of mild soap, then dry immediately. Store the spare face plates and effect parts in the box, and if you display a large figure, support the base to stop it leaning over time.",
    keywords: "care,figure,clean,dust,maintain,pvc,display,sunlight,paint,collectible",
    topic: "Merch Care",
    imageUrl: "assets/images/products/luffy_gear5_figure.jpg",
  },
  {
    question: "How should I wash my fandom shirt?",
    answer:
      "Turn the tee inside out and wash it cold on a gentle cycle - heat is what cracks screen prints. Do not use bleach or fabric softener, and skip the dryer: hang it to dry in the shade. If the print looks dull, iron only the inside surface. Follow this and the graphic will stay sharp for years.",
    keywords: "shirt,tee,wash,laundry,care,apparel,print,iron,dry",
    topic: "Merch Care",
    imageUrl: "assets/images/products/straw_hat_crew_tee.jpg",
  },
  {
    question: "Suggestions for anime?",
    answer:
      "If you are starting out, try these five: One Piece for a long adventure that keeps rewarding you, Demon Slayer for gorgeous animation and a tight story, Jujutsu Kaisen for modern action and great fights, Attack on Titan for a dark plot with huge reveals, and Fullmetal Alchemist: Brotherhood for a perfectly paced complete story. Want something calmer? Studio Ghibli films like Spirited Away and My Neighbour Totoro are the gentlest entry point.",
    keywords: "suggest,suggestion,recommend,recommendation,anime,watch,start,best,beginner,list,top",
    topic: "Recommendations",
    imageUrl: "assets/images/products/shonen_starter_bundle.jpg",
  },
  {
    question: "Which manga should I read first?",
    answer:
      "Start with a completed series so you get a full story: Death Note (12 volumes, a perfect thriller), Fullmetal Alchemist (27 volumes, consistently excellent) or Demon Slayer (23 volumes, fast paced). If you want to catch up with everyone else, read One Piece alongside the anime - the manga is much further ahead of the anime.",
    keywords: "manga,read,volume,comics,start,beginner,which,first,death note",
    topic: "Recommendations",
    imageUrl: "assets/images/products/manga_lettering_font_bundle.jpg",
  },
  {
    question: "Where is my order?",
    answer:
      "This store uses a simulated checkout, so no real payment or shipping happens - your order is saved as a bill you can review any time from the Orders screen in your profile. Open the Shop tab, tap the receipt icon and you will see the full itemised summary with the order code.",
    keywords: "order,track,tracking,delivery,shipping,status,where,my order,when",
    topic: "Store Help",
    imageUrl: "assets/images/products/one_piece_collector_box.jpg",
  },
  {
    question: "How do I use my wishlist?",
    answer:
      "Tap the heart on any product to add it to your wishlist - the Wishlist screen in the Shop tab keeps everything in one place. The store also watches prices for you: if something on your wishlist drops in price you get a notification with the old and new price so you can grab the deal.",
    keywords: "wishlist,save,saved,heart,favourite,favorite,price drop,alert,discount",
    topic: "Store Help",
    imageUrl: "assets/images/products/straw_hat_keychain.jpg",
  },
  {
    question: "How does the cart and checkout work?",
    answer:
      "Add products to your cart, then open the Cart screen to change quantities or remove items. Checkout shows a full order summary - subtotal, discount, shipping and the grand total - and confirming places your simulated order. Because payments and delivery are outside the scope of this app, you are simply shown the bill and an order confirmation.",
    keywords: "cart,checkout,buy,bill,total,payment,pay,order,quantity,remove",
    topic: "Store Help",
    imageUrl: "assets/images/products/anime_enamel_pin_set.jpg",
  },
  {
    question: "Is this merchandise official?",
    answer:
      "Every item in the catalogue is listed against its official brand - Toei Animation, Studio Pierrot, Aniplex, MAPPA, Kodansha and so on - and box sets are produced by the Fandom Verse Vault. Each product page shows the brand, the fandom and the stock status so you always know exactly what you are buying.",
    keywords: "official,genuine,authentic,brand,real,licensed",
    topic: "Store Help",
    imageUrl: "assets/images/products/one_piece_collector_box.jpg",
  },
  {
    question: "How do I choose the right cosplay wig?",
    answer:
      "Match the fibre to the job. Heat-resistant synthetic fibre is the best all-rounder - it holds a styled shape and tolerates low-temperature irons. Look for a lace-front cap if you want a natural hairline, buy one shade lighter than the character art if you will be shooting in bright light, and always order the wig cap. Wash it in cold water with wig shampoo after every convention.",
    keywords: "cosplay,wig,hair,style,fibre,fiber,lace front,costume,character",
    topic: "Cosplay",
    imageUrl: "assets/images/products/cosplay_wig_care_kit.jpg",
  },
  {
    question: "What are the best fandom gift ideas?",
    answer:
      "Figure collectors love the One Piece Collector Box and the Studio Ghibli Art Collection because both are limited runs. For a safer gift, the Anime Enamel Pin Set and the Straw Hat Keychain work for any fan, and the Anime 4K Wallpaper Pack is an instant-delivery digital gift if you are shopping last minute.",
    keywords: "gift,gifts,present,idea,ideas,birthday,give,christmas",
    topic: "Recommendations",
    imageUrl: "assets/images/products/ghibli_art_collection.jpg",
  },
  {
    question: "What is a fandom?",
    answer:
      "A fandom is a subculture of fans who share a common interest - a series, a game, an artist or a universe - and who create things around it together: fan art, fan fiction, cosplay, theories and discussions. Fandom Verse exists to bring those scattered conversations, events and merchandise into one place.",
    keywords: "fandom,fan,community,what is,meaning,subculture",
    topic: "Fandoms",
    imageUrl: "assets/images/products/anime_4k_wallpaper_pack.jpg",
  },
  {
    question: "What is cosplay?",
    answer:
      "Cosplay is costume play - dressing up as a character from a fandom, usually building or assembling the outfit yourself and posing for photos. It ranges from a simple closet cosplay with one key accessory to competition-grade builds with armour, wigs and props. Conventions usually run a cosplay contest with a craftsmanship category.",
    keywords: "cosplay,costume,dress up,convention,competition,prop,armour,armor",
    topic: "Fandoms",
    imageUrl: "assets/images/products/cosplay_pose_reference_pack.jpg",
  },
  {
    question: "Which events are near me?",
    answer:
      "Open the Events tab to see conventions, cosplay meetups and screenings close to your city - the Map and Calendar screens let you browse by date and location. New events are added regularly, and you can tap Interested on any event to be reminded about it later.",
    keywords: "event,events,near,convention,meetup,calendar,map,comic con,nearby",
    topic: "Events",
    imageUrl: "assets/images/products/shonen_starter_bundle.jpg",
  },
];

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------
async function seed() {
  console.log("Seeding Member 5 - Merchandise Store + AI Fan Helper...\n");

  // ---------------------------- categories ----------------------------
  console.log("Product categories:");
  const categoryIds = {};
  for (let i = 0; i < categories.length; i++) {
    const [name, slug, icon, color, description] = categories[i];
    const result = await insertIfMissing(
      "product_categories",
      "slug",
      slug,
      `INSERT INTO product_categories (name, slug, icon, color, description, sort_order)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [name, slug, icon, color, description, i]
    );
    categoryIds[name] = result.id;
    console.log(`  ${result.created ? "+" : "="} ${name}`);
  }

  // ----------------------------- products -----------------------------
  console.log("\nProducts:");
  let createdProducts = 0;
  for (const product of products) {
    const discount =
      product.oldPrice && product.oldPrice > product.price
        ? Math.round(((product.oldPrice - product.price) / product.oldPrice) * 100)
        : 0;

    const result = await insertIfMissing(
      "products",
      "sku",
      product.slug.toUpperCase(),
      `INSERT INTO products
         (name, sku, description, category, fandom, brand, price, old_price,
          discount_percent, currency, image_url, stock, rating, rating_count,
          sold_count, is_featured, is_digital, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'USD', ?, ?, ?, ?, ?, ?, ?, 'active')`,
      [
        product.name,
        product.slug.toUpperCase(),
        product.description,
        product.category,
        product.fandom,
        product.brand,
        product.price,
        product.oldPrice,
        discount,
        `assets/images/products/${product.slug}.jpg`,
        product.stock,
        product.rating,
        product.ratingCount,
        product.soldCount,
        product.featured ?? 0,
        product.digital ?? 0,
      ]
    );

    if (result.created) createdProducts++;
  }
  console.log(`  ${createdProducts} new / ${products.length} total`);

  // ------------------------------- FAQs -------------------------------
  console.log("\nAI Fan Helper knowledge base:");
  let createdFaqs = 0;
  for (const faq of faqs) {
    const result = await insertIfMissing(
      "ai_faqs",
      "question",
      faq.question,
      `INSERT INTO ai_faqs (question, answer, keywords, topic, image_url)
       VALUES (?, ?, ?, ?, ?)`,
      [faq.question, faq.answer, faq.keywords, faq.topic, faq.imageUrl]
    );
    if (result.created) createdFaqs++;
  }
  console.log(`  ${createdFaqs} new / ${faqs.length} total`);

  // ------------------------- demo data for Emma -------------------------
  const emma = await get(`SELECT id, name FROM users WHERE email = ?`, [
    "emma@fandomverse.com",
  ]);

  if (!emma) {
    console.log(
      "\nDemo user emma@fandomverse.com not found - skipping wishlist/cart/order demo data."
    );
  } else {
    console.log(`\nDemo data for ${emma.name} (user ${emma.id}):`);

    // Wishlist. Two rows deliberately store a HIGHER price_at_save than the
    // product's current price so the price-drop alert feature has something
    // real to detect on first launch.
    const wishlist = [
      { sku: "LUFFY_GEAR5_FIGURE", priceAtSave: 44.99 },
      { sku: "NARUTO_SAGE_FIGURE", priceAtSave: 49.99 },
      { sku: "STRAW_HAT_KEYCHAIN", priceAtSave: 13.99 },
      { sku: "STRAW_HAT_CREW_TEE", priceAtSave: 32.99 },
    ];

    let newWishes = 0;
    for (const item of wishlist) {
      const product = await get(`SELECT id, price FROM products WHERE sku = ?`, [
        item.sku,
      ]);
      if (!product) continue;

      const existing = await get(
        `SELECT id FROM wishlists WHERE user_id = ? AND product_id = ?`,
        [emma.id, product.id]
      );
      if (existing) continue;

      await run(
        `INSERT INTO wishlists (user_id, product_id, price_at_save)
         VALUES (?, ?, ?)`,
        [emma.id, product.id, item.priceAtSave]
      );
      newWishes++;
    }
    console.log(`  wishlist items added: ${newWishes}`);

    // Cart - two items, one of them a quantity of 2 so the bill maths is visible.
    const cart = [
      { sku: "GOJO_SATORU_FIGURE", quantity: 1 },
      { sku: "ANIME_ENAMEL_PIN_SET", quantity: 2 },
    ];

    let newCartItems = 0;
    for (const item of cart) {
      const product = await get(`SELECT id FROM products WHERE sku = ?`, [item.sku]);
      if (!product) continue;

      const existing = await get(
        `SELECT id FROM cart_items WHERE user_id = ? AND product_id = ?`,
        [emma.id, product.id]
      );
      if (existing) continue;

      await run(
        `INSERT INTO cart_items (user_id, product_id, quantity) VALUES (?, ?, ?)`,
        [emma.id, product.id, item.quantity]
      );
      newCartItems++;
    }
    console.log(`  cart items added: ${newCartItems}`);

    // One past order so the Orders / purchase-history screen has data.
    const existingOrder = await get(
      `SELECT id FROM orders WHERE user_id = ? LIMIT 1`,
      [emma.id]
    );

    if (!existingOrder) {
      const orderedSkus = [
        { sku: "TANJIRO_KAMADO_FIGURE", quantity: 1 },
        { sku: "NEZUKO_KAMADO_FIGURE", quantity: 1 },
      ];

      const lines = [];
      let subtotal = 0;

      for (const item of orderedSkus) {
        const product = await get(
          `SELECT id, name, price, image_url FROM products WHERE sku = ?`,
          [item.sku]
        );
        if (!product) continue;

        const lineTotal = +(product.price * item.quantity).toFixed(2);
        subtotal += lineTotal;
        lines.push({ product, quantity: item.quantity, lineTotal });
      }

      if (lines.length) {
        const shipping = 0;
        const total = +(subtotal + shipping).toFixed(2);
        const orderCode = `FV-${Date.now().toString().slice(-6)}`;

        const order = await run(
          `INSERT INTO orders
             (user_id, order_code, item_count, subtotal, discount, shipping_fee,
              total, currency, status, payment_method, shipping_name,
              shipping_city, shipping_address, placed_at)
           VALUES (?, ?, ?, ?, 0, ?, ?, 'USD', 'delivered',
                   'Cash on Delivery (simulated)', ?, 'Karachi',
                   'Demo address, Gulshan-e-Iqbal', datetime('now', '-6 days'))`,
          [
            emma.id,
            orderCode,
            lines.reduce((sum, line) => sum + line.quantity, 0),
            +subtotal.toFixed(2),
            shipping,
            total,
            emma.name,
          ]
        );

        for (const line of lines) {
          await run(
            `INSERT INTO order_items
               (order_id, product_id, name, image_url, unit_price, quantity, line_total)
             VALUES (?, ?, ?, ?, ?, ?, ?)`,
            [
              order.lastID,
              line.product.id,
              line.product.name,
              line.product.image_url,
              line.product.price,
              line.quantity,
              line.lineTotal,
            ]
          );
        }

        console.log(`  past order created: ${orderCode} (${total.toFixed(2)} USD)`);
      }
    } else {
      console.log("  past order already exists");
    }
  }

  console.log("\nDone. Merchandise + AI Fan Helper data is ready.");
}

seed()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Seed failed:", error.message);
    process.exit(1);
  });

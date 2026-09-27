import os
import shutil

assets_dir = r"c:\Users\TLS\Desktop\Fandomverse\TechwizProject\frontend\assets\images"

artworks = {
    "luffy": os.path.join(assets_dir, "content", "luffy_lore.jpg"),
    "gojo": os.path.join(assets_dir, "content", "gojo_jjk.jpg"),
    "demon_slayer": os.path.join(assets_dir, "content", "demon_slayer.jpg"),
    "anime_expo": os.path.join(assets_dir, "events", "anime_expo_2025.jpg"),
    "figure": os.path.join(assets_dir, "products", "figure_luna.jpg"),
    "splash": os.path.join(assets_dir, "splash_bg.jpg"),
}

def replace_all():
    print("Replacing ALL asset images with custom-generated high-res anime artwork...")
    
    artwork_list = [artworks["luffy"], artworks["gojo"], artworks["demon_slayer"], artworks["anime_expo"], artworks["figure"]]
    idx = 0

    for root, dirs, files in os.walk(assets_dir):
        for file in files:
            if not file.endswith((".jpg", ".png", ".jpeg")):
                continue
            
            target_path = os.path.normpath(os.path.join(root, file))
            
            # Check if target is one of the source artworks
            if any(os.path.normpath(art) == target_path for art in artworks.values()):
                continue

            src_art = artwork_list[idx % len(artwork_list)]
            if "luffy" in file.lower() or "one_piece" in file.lower() or "naruto" in file.lower():
                src_art = artworks["luffy"]
            elif "gojo" in file.lower() or "jjk" in file.lower() or "curse" in file.lower():
                src_art = artworks["gojo"]
            elif "demon" in file.lower() or "tanjiro" in file.lower() or "nezuko" in file.lower():
                src_art = artworks["demon_slayer"]
            elif "figure" in file.lower() or "product" in file.lower() or "shop" in file.lower():
                src_art = artworks["figure"]
            elif "event" in file.lower() or "expo" in file.lower() or "con" in file.lower():
                src_art = artworks["anime_expo"]
            
            try:
                if os.path.normpath(src_art) != target_path:
                    shutil.copyfile(src_art, target_path)
            except Exception as e:
                print(f"Skipping {file}: {e}")
            idx += 1

    print("ALL app asset images replaced with high-res custom anime artwork successfully!")

if __name__ == "__main__":
    replace_all()

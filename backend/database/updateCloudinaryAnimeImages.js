/**
 * Updates avatars, content, and shop with unique custom-generated anime images.
 */

import db from "./db.js";
import { initContentSchema } from "./contentSchema.js";
import { initEventsSchema } from "./eventsSchema.js";
import { initShopSchema } from "./shopSchema.js";
import { initProfileSchema } from "./profileSchema.js";

initContentSchema();
initEventsSchema();
initShopSchema();
initProfileSchema();

function runAsync(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) reject(err);
      else resolve(this);
    });
  });
}

async function updateAll() {
  console.log("Updating avatars and content items with custom anime images...");

  // Avatars
  await runAsync(`UPDATE users SET avatar = 'assets/images/avatars/avatar_01.jpg' WHERE email LIKE 'emma%' OR id = 1`);
  await runAsync(`UPDATE users SET avatar = 'assets/images/avatars/avatar_02.jpg' WHERE id = 2 OR email LIKE 'admin%'`);

  // Content Items
  await runAsync(`UPDATE content_items SET image_url = 'assets/images/content/gallery_01.jpg' WHERE content_type = 'gallery' OR title LIKE '%Cyberpunk%'`);
  await runAsync(`UPDATE content_items SET image_url = 'assets/images/content/luffy_lore.jpg' WHERE title LIKE '%One Piece%' OR title LIKE '%Wano%'`);
  await runAsync(`UPDATE content_items SET image_url = 'assets/images/content/gojo_jjk.jpg' WHERE title LIKE '%Jujutsu%' OR title LIKE '%Gojo%'`);
  await runAsync(`UPDATE content_items SET image_url = 'assets/images/content/demon_slayer.jpg' WHERE title LIKE '%Demon%' OR title LIKE '%Slayer%'`);
  await runAsync(`UPDATE content_items SET image_url = 'assets/images/events/comic_con.jpg' WHERE id = 9`);
  await runAsync(`UPDATE content_items SET image_url = 'assets/images/content/gallery_06.jpg' WHERE id = 12`);
  await runAsync(`UPDATE content_items SET image_url = 'assets/images/content/gallery_02.jpg' WHERE id = 16`);
  await runAsync(`UPDATE content_items SET image_url = 'assets/images/content/gallery_03.jpg' WHERE id = 17`);
  await runAsync(`UPDATE content_items SET image_url = 'assets/images/content/gallery_04.jpg' WHERE id = 18`);
  await runAsync(`UPDATE content_items SET image_url = 'assets/images/content/gallery_05.jpg' WHERE id = 19`);
  await runAsync(`UPDATE content_items SET image_url = 'assets/images/content/gallery_06.jpg' WHERE id = 20`);
  await runAsync(`UPDATE content_items SET image_url = 'assets/images/content/rpg_speedrun.jpg' WHERE id = 2 OR title LIKE '%speedrun%'`);

  console.log("✅ Avatars and Content images updated successfully!");
  db.close();
}

updateAll().catch((err) => {
  console.error("Error updating images:", err);
  db.close();
});

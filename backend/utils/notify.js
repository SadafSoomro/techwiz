/**
 * Notification helper used by the Search & Community module.
 * Creates rows in the `notifications` table which power the
 * Notifications screen (new follower / liked your post / new comment).
 */

import { run, get } from "../database/dbhelpers.js";

/**
 * @param {object} options
 * @param {number} options.userId      receiver of the notification
 * @param {number} options.actorId     user who triggered it
 * @param {string} options.type        follow | like | comment | bookmark | system
 * @param {string} options.message     display text
 * @param {number} [options.referenceId] related post id
 */
export async function notify({ userId, actorId, type, message, referenceId = null }) {
  try {
    if (!userId) return;
    // never notify yourself
    if (actorId && Number(actorId) === Number(userId)) return;

    await run(
      `INSERT INTO notifications (user_id, actor_id, type, message, reference_id)
       VALUES (?, ?, ?, ?, ?)`,
      [userId, actorId ?? null, type, message, referenceId]
    );
  } catch (error) {
    console.error("[notify]", error.message);
  }
}

/** Builds "John Doe liked your post" using the actor's name. */
export async function notifyWithActor({ userId, actorId, type, action, referenceId = null }) {
  const actor = actorId
    ? await get(`SELECT name FROM users WHERE id = ?`, [actorId])
    : null;
  const actorName = actor?.name || "Someone";

  await notify({
    userId,
    actorId,
    type,
    message: `${actorName} ${action}`,
    referenceId,
  });
}

export default { notify, notifyWithActor };

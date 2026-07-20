import { db } from '../../shared/drizzle.ts';
import { rooms, messages } from '../../db/schema.ts';
import { eq } from 'drizzle-orm';

/**
 * Creates a chat room if it does not exist, otherwise returns the existing record.
 */
export async function upsertChatRoom(roomId: string, driverId: string, passengerId: string) {
  const insertedRecords = await db.insert(rooms)
    .values({ id: roomId, driverId, passengerId })
    .onConflictDoNothing()
    .returning();

  if (insertedRecords.length > 0) {
    return insertedRecords[0];
  }

  return await fetchChatRoomDetails(roomId);
}

/**
 * Retrieves all chat message records for a specific chat room ordered by creation time.
 */
export async function fetchChatRoomMessages(roomId: string) {
  return await db.select()
    .from(messages)
    .where(eq(messages.roomId, roomId))
    .orderBy(messages.createdAt);
}

/**
 * Retrieves the details of a specific chat room by its identifier.
 */
export async function fetchChatRoomDetails(roomId: string) {
  const matchedRooms = await db.select()
    .from(rooms)
    .where(eq(rooms.id, roomId));
  return matchedRooms[0] || null;
}

/**
 * Appends a new chat message to the database records for a target room.
 */
export async function insertChatMessage(roomId: string, senderId: string, text: string) {
  const insertedMessages = await db.insert(messages)
    .values({ roomId, senderId, message: text })
    .returning();
  return insertedMessages[0];
}

/**
 * Retrieves recent message logs up to a defined retrieval limit.
 */
export async function fetchRecentChatMessages(roomId: string, messageLimit = 50) {
  return await db.select()
    .from(messages)
    .where(eq(messages.roomId, roomId))
    .orderBy(messages.createdAt)
    .limit(messageLimit);
}

/**
 * Flags a specific conversation room as resolved, locking future message dispatches.
 */
export async function markChatRoomAsResolved(roomId: string) {
  const updatedRooms = await db.update(rooms)
    .set({ resolved: true })
    .where(eq(rooms.id, roomId))
    .returning();
  return updatedRooms[0];
}

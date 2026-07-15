/**
 * Service layer orchestrating domain business validations and mapping repository operations.
 */
import {
  upsertChatRoom,
  fetchChatRoomMessages,
  fetchChatRoomDetails,
  insertChatMessage,
  fetchRecentChatMessages,
  markChatRoomAsResolved,
} from './chat.repository.ts';

/**
 * Global map storing active WebSocket connections indexed by room identifier.
 */
export const activeChatConnectionsMap = new Map<string, Set<any>>();

/**
 * Creates a new chat room record or returns the existing matching conversation.
 */
export async function createOrGetChatRoom(roomId: string, driverId: string, passengerId: string) {
  return await upsertChatRoom(roomId, driverId, passengerId);
}

/**
 * Retrieves the complete message list for a specific chat room.
 */
export async function getChatRoomMessages(roomId: string) {
  return await fetchChatRoomMessages(roomId);
}

/**
 * Fetches specific details of a chat room by its unique identifier.
 */
export async function getChatRoomDetails(roomId: string) {
  return await fetchChatRoomDetails(roomId);
}

/**
 * Persists a new text message entry associated with a chat room and sender.
 */
export async function saveChatMessage(roomId: string, senderId: string, text: string) {
  return await insertChatMessage(roomId, senderId, text);
}

/**
 * Fetches recent message logs within the retrieval limit boundaries.
 */
export async function getRecentChatMessages(roomId: string, messageLimit = 50) {
  return await fetchRecentChatMessages(roomId, messageLimit);
}

/**
 * Updates the conversation status to resolved, locking the chat room.
 */
export async function resolveChatRoom(roomId: string) {
  return await markChatRoomAsResolved(roomId);
}

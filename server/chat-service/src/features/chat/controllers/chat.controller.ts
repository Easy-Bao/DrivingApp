/**
 * Controller layer processing HTTP request context and mapping WebSocket connection lifecycle.
 */
import { Context } from 'hono';
import { verify } from 'hono/jwt';
import { HTTPException } from 'hono/http-exception';
import {
  createOrGetChatRoom,
  getChatRoomMessages,
  getChatRoomDetails,
  saveChatMessage,
  getRecentChatMessages,
  resolveChatRoom,
  activeChatConnectionsMap,
} from '../services/chat.service.ts';
import { Logger } from '../../../shared/logger/logger.ts';

if (!process.env.TRIP_SERVICE_URL) {
  throw new Error("Configuration Error: TRIP_SERVICE_URL is required but not set.");
}
const TRIP_SERVICE_URL = process.env.TRIP_SERVICE_URL;
const jwtSecret = process.env.JWT_SECRET;

/**
 * Creates a new chat room or returns the existing matching conversation.
 */
export async function handleCreateChatRoom(context: Context) {
  const { roomId, driverId, passengerId } = await context.req.json();
  if (!roomId || !driverId || !passengerId) {
    throw new HTTPException(400, { message: 'roomId, driverId, and passengerId are required' });
  }
  await createOrGetChatRoom(roomId, driverId, passengerId);
  return context.json({ success: true }, 201);
}

/**
 * Retrieves the complete message history for a target room.
 */
export async function handleGetChatRoomMessages(context: Context) {
  const roomId = context.req.param('roomId');
  const messagesList = await getChatRoomMessages(roomId);
  return context.json(messagesList);
}

/**
 * Flags a specific chat room as resolved and alerts connected peers.
 */
export async function handleResolveChatRoom(context: Context) {
  const roomId = context.req.param('roomId');
  await resolveChatRoom(roomId);

  // Broadcast lock to all connected clients
  const activePeers = activeChatConnectionsMap.get(roomId);
  if (activePeers) {
    const lockWarningMessage = JSON.stringify({
      type: 'locked',
      reason: 'This conversation has been resolved.',
    });
    for (const peer of activePeers) {
      peer.send(lockWarningMessage);
    }
  }

  return context.json({ success: true });
}

/**
 * Handles validation and state verification for real-time WebSocket session updates.
 */
export async function handleWebSocketUpgrade(context: Context) {
  const roomId = context.req.query('roomId');
  const userId = context.req.query('userId');
  const token = context.req.query('token');

  if (!roomId) {
    return {
      onOpen(_event: any, ws: any) {
        ws.close(4000, 'Room ID is required');
      },
    };
  }

  let finalUserId = userId || '';
  if (token && jwtSecret) {
    try {
      const decodedClaims = await verify(token, jwtSecret, "HS256");
      if (decodedClaims && decodedClaims.sub) {
        finalUserId = decodedClaims.sub.toString();
      }
    } catch (_) {}
  }

  if (!finalUserId) {
    return {
      onOpen(_event: any, ws: any) {
        ws.close(4001, 'Unauthorized');
      },
    };
  }

  let room = await getChatRoomDetails(roomId);
  let isRoomLocked = false;
  let lockReason = '';

  let completedAtString: string | null = null;
  try {
    const response = await fetch(`${TRIP_SERVICE_URL}/rides/${roomId}`);
    if (response.ok) {
      const ride = await response.json() as any;
      if (!room && ride && ride.driver_id && ride.passenger_id) {
        room = await createOrGetChatRoom(roomId, ride.driver_id, ride.passenger_id);
      }
      if (ride && ride.completed_at) {
        completedAtString = ride.completed_at;
      }
    }
  } catch (error) {
    Logger.error(`Failed to dynamically resolve ride status for ${roomId} from trip-service:`, error);
  }

  if (!room) {
    return {
      onOpen(_event: any, ws: any) {
        ws.close(4004, 'Room not found');
      },
    };
  }

  if (room.resolved) {
    isRoomLocked = true;
    lockReason = 'This conversation has been resolved.';
  }

  if (completedAtString) {
    const completedAt = new Date(completedAtString);
    const msSinceCompletion = Date.now() - completedAt.getTime();
    const hoursSinceCompletion = msSinceCompletion / (1000 * 60 * 60);
    if (hoursSinceCompletion > 48) {
      isRoomLocked = true;
      lockReason = 'This chat session has expired.';
    }
  }

  if (room.driverId !== finalUserId && room.passengerId !== finalUserId) {
    return {
      onOpen(_event: any, ws: any) {
        ws.close(4003, 'Forbidden');
      },
    };
  }

  return {
    async onOpen(_event: any, ws: any) {
      if (!activeChatConnectionsMap.has(roomId)) {
        activeChatConnectionsMap.set(roomId, new Set());
      }
      activeChatConnectionsMap.get(roomId)!.add(ws);

      const msgHistory = await getRecentChatMessages(roomId, 50);
      const messages = msgHistory.map((msg) => ({
        senderId: msg.senderId,
        text: msg.message,
        createdAt: msg.createdAt,
      }));

      ws.send(JSON.stringify({ type: 'history', messages }));

      if (isRoomLocked) {
        ws.send(JSON.stringify({ type: 'locked', reason: lockReason }));
      }
    },
    async onMessage(websocketMessageEvent: any, _ws: any) {
      if (isRoomLocked) {
        return;
      }
      try {
        const payload = JSON.parse(websocketMessageEvent.data.toString());
        const text = payload.text;
        if (!text) return;

        await saveChatMessage(roomId, finalUserId, text);

        const broadcastMsg = JSON.stringify({
          type: 'message',
          roomId,
          senderId: finalUserId,
          text,
          createdAt: new Date().toISOString(),
        });

        const activePeers = activeChatConnectionsMap.get(roomId);
        if (activePeers) {
          for (const peer of activePeers) {
            peer.send(broadcastMsg);
          }
        }
      } catch (_) {}
    },
    onClose(_event: any, ws: any) {
      const activePeers = activeChatConnectionsMap.get(roomId);
      if (activePeers) {
        activePeers.delete(ws);
        if (activePeers.size === 0) {
          activeChatConnectionsMap.delete(roomId);
        }
      }
    },
  };
}

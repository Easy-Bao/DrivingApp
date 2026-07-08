import { Hono } from 'hono';
import { verify } from 'hono/jwt';
import { upgradeWebSocket } from 'hono/bun';
import {
  upsertRoom,
  getRoomMessages,
  getRoomDetails,
  addMessageToHistory,
  getRecentRoomMessages,
  activeConnections,
  resolveRoom,
} from '../services/chat.ts';

const jwtSecret = process.env.JWT_SECRET;

export const chatRouter = new Hono();

chatRouter.post('/rooms', async (context) => {
  try {
    const { roomId, driverId, passengerId } = await context.req.json();
    if (!roomId || !driverId || !passengerId) {
      return context.json({ error: 'roomId, driverId, and passengerId are required' }, 400);
    }
    await upsertRoom(roomId, driverId, passengerId);
    return context.json({ success: true }, 201);
  } catch (error: any) {
    return context.json({ error: error.message }, 500);
  }
});

chatRouter.get('/rooms/:roomId/messages', async (context) => {
  const roomId = context.req.param('roomId');
  try {
    const res = await getRoomMessages(roomId);
    return context.json(res);
  } catch (error: any) {
    return context.json({ error: error.message }, 500);
  }
});

chatRouter.post('/rooms/:roomId/resolve', async (context) => {
  const chatRoomIdentifier = context.req.param('roomId');
  try {
    await resolveRoom(chatRoomIdentifier);

    // Broadcast lock to all connected clients
    const activeRoomPeers = activeConnections.get(chatRoomIdentifier);
    if (activeRoomPeers) {
      const lockWarningMessage = JSON.stringify({
        type: 'locked',
        reason: 'This conversation has been resolved.',
      });
      for (const activePeer of activeRoomPeers) {
        activePeer.send(lockWarningMessage);
      }
    }

    return context.json({ success: true });
  } catch (caughtError: any) {
    return context.json({ error: caughtError.message }, 500);
  }
});

chatRouter.get('/ws', upgradeWebSocket(async (context) => {
  const roomId = context.req.query('roomId');
  const userId = context.req.query('userId');
  const token = context.req.query('token');

  if (!roomId) {
    return {
      onOpen(_event, ws) {
        ws.close(4000, 'Room ID is required');
      }
    };
  }

  let finalUserId = userId || '';
  if (token && jwtSecret) {
    try {
      const decodedTokenClaims = await verify(token, jwtSecret, "HS256");
      if (decodedTokenClaims && decodedTokenClaims.sub) {
        finalUserId = decodedTokenClaims.sub.toString();
      }
    } catch (_) { }
  }

  if (!finalUserId) {
    return {
      onOpen(_event, ws) {
        ws.close(4001, 'Unauthorized');
      }
    };
  }

  let room = await getRoomDetails(roomId);
  let isRoomLocked = false;
  let lockReason = '';

  const tripServiceUrl = process.env.TRIP_SERVICE_URL || 'http://127.0.0.1:8083';
  let completedAtString: string | null = null;
  try {
    const response = await fetch(`${tripServiceUrl}/rides/${roomId}`);
    if (response.ok) {
      const ride = await response.json() as any;
      if (!room && ride && ride.driver_id && ride.passenger_id) {
        room = await upsertRoom(roomId, ride.driver_id, ride.passenger_id);
      }
      if (ride && ride.completed_at) {
        completedAtString = ride.completed_at;
      }
    }
  } catch (error) {
    console.error(`Failed to dynamically resolve ride status for ${roomId} from trip-service:`, error);
  }

  if (!room) {
    return {
      onOpen(_event, ws) {
        ws.close(4004, 'Room not found');
      }
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
      onOpen(_event, ws) {
        ws.close(4003, 'Forbidden');
      }
    };
  }

  return {
    async onOpen(_event, ws) {
      if (!activeConnections.has(roomId)) {
        activeConnections.set(roomId, new Set());
      }
      activeConnections.get(roomId)!.add(ws);

      const msgHistory = await getRecentRoomMessages(roomId, 50);
      const messages = msgHistory.map((messageItem) => ({
        senderId: messageItem.senderId,
        text: messageItem.message,
        createdAt: messageItem.createdAt,
      }));

      ws.send(JSON.stringify({ type: 'history', messages }));

      if (isRoomLocked) {
        ws.send(JSON.stringify({ type: 'locked', reason: lockReason }));
      }
    },
    async onMessage(websocketMessageEvent, _ws) {
      if (isRoomLocked) {
        return;
      }
      try {
        const payload = JSON.parse(websocketMessageEvent.data.toString());
        const text = payload.text;
        if (!text) return;

        await addMessageToHistory(roomId, finalUserId, text);

        const broadcastMsg = JSON.stringify({
          type: 'message',
          roomId,
          senderId: finalUserId,
          text,
          createdAt: new Date().toISOString(),
        });

        const activeRoomPeers = activeConnections.get(roomId);
        if (activeRoomPeers) {
          for (const activePeer of activeRoomPeers) {
            activePeer.send(broadcastMsg);
          }
        }
      } catch (_) { }
    },
    onClose(_event, ws) {
      const activeRoomPeers = activeConnections.get(roomId);
      if (activeRoomPeers) {
        activeRoomPeers.delete(ws);
        if (activeRoomPeers.size === 0) {
          activeConnections.delete(roomId);
        }
      }
    }
  };
}));

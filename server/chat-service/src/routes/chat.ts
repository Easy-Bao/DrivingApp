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
} from '../services/chat.ts';

const jwtSecret = process.env.JWT_SECRET;

export const chatRouter = new Hono();

chatRouter.post('/rooms', async (c) => {
  try {
    const { roomId, driverId, passengerId } = await c.req.json();
    if (!roomId || !driverId || !passengerId) {
      return c.json({ error: 'roomId, driverId, and passengerId are required' }, 400);
    }
    await upsertRoom(roomId, driverId, passengerId);
    return c.json({ success: true }, 201);
  } catch (e: any) {
    return c.json({ error: e.message }, 500);
  }
});

chatRouter.get('/rooms/:roomId/messages', async (c) => {
  const roomId = c.req.param('roomId');
  try {
    const res = await getRoomMessages(roomId);
    return c.json(res);
  } catch (e: any) {
    return c.json({ error: e.message }, 500);
  }
});

chatRouter.get('/ws', upgradeWebSocket(async (c) => {
  const roomId = c.req.query('roomId');
  const userId = c.req.query('userId');
  const token = c.req.query('token');

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
      const decoded = await verify(token, jwtSecret, "HS256");
      if (decoded && decoded.sub) {
        finalUserId = decoded.sub.toString();
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

  const room = await getRoomDetails(roomId);
  if (!room) {
    return {
      onOpen(_event, ws) {
        ws.close(4004, 'Room not found');
      }
    };
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
      const messages = msgHistory.map((m) => ({
        senderId: m.senderId,
        text: m.message,
        createdAt: m.createdAt,
      }));

      ws.send(JSON.stringify({ type: 'history', messages }));
    },
    async onMessage(event, _ws) {
      try {
        const payload = JSON.parse(event.data.toString());
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

        const peers = activeConnections.get(roomId);
        if (peers) {
          for (const peer of peers) {
            peer.send(broadcastMsg);
          }
        }
      } catch (_) { }
    },
    onClose(_event, ws) {
      const peers = activeConnections.get(roomId);
      if (peers) {
        peers.delete(ws);
        if (peers.size === 0) {
          activeConnections.delete(roomId);
        }
      }
    }
  };
}));

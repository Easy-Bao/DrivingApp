import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { upgradeWebSocket, websocket } from 'hono/bun';
import { prisma } from './db.ts';
import { verify } from 'hono/jwt';

const app = new Hono();

app.use('*', cors());

const jwtSecret = process.env.JWT_SECRET;

const activeConnections = new Map<string, Set<any>>();

app.post('/chat/rooms', async (c) => {
  try {
    const { roomId, driverId, passengerId } = await c.req.json();
    if (!roomId || !driverId || !passengerId) {
      return c.json({ error: 'roomId, driverId, and passengerId are required' }, 400);
    }
    await prisma.room.upsert({
      where: { id: roomId },
      update: {},
      create: {
        id: roomId,
        driverId,
        passengerId,
      },
    });
    return c.json({ success: true }, 201);
  } catch (e: any) {
    return c.json({ error: e.message }, 500);
  }
});

app.get('/chat/rooms/:roomId/messages', async (c) => {
  const roomId = c.req.param('roomId');
  try {
    const res = await prisma.message.findMany({
      where: { roomId },
      orderBy: { createdAt: 'asc' },
    });
    return c.json(res);
  } catch (e: any) {
    return c.json({ error: e.message }, 500);
  }
});

app.get('/chat/ws', upgradeWebSocket(async (c) => {
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

  const room = await prisma.room.findUnique({
    where: { id: roomId },
  });

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

      const msgHistory = await prisma.message.findMany({
        where: { roomId },
        orderBy: { createdAt: 'asc' },
        take: 50,
      });

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

        await prisma.message.create({
          data: {
            roomId,
            senderId: finalUserId,
            message: text,
          },
        });

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

app.get('/', (c) => c.json({ status: 'Chat Service OK' }));

const port = parseInt(process.env.PORT || '8086');

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
  websocket,
};

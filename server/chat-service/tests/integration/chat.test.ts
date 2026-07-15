/// Chat service integration tests: verifies REST room creation, WebSocket connectivity, and messaging.
import { expect, test, describe, beforeAll, afterAll } from 'bun:test';
import chatApp from '../../src/index.ts';
import { db } from '../../src/shared/drizzle.ts';
import { rooms } from '../../src/db/schema.ts';

let server: any;

beforeAll(async () => {
  server = Bun.serve(chatApp);
  await db.delete(rooms);
});

afterAll(async () => {
  server.stop(true);
});

describe('Chat Service', () => {
  test('POST /chat/rooms - registers a new room', async () => {
    const res = await fetch('http://localhost:8086/chat/rooms', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        roomId: 'test-room-123',
        driverId: 'driver-id-abc',
        passengerId: 'passenger-id-xyz',
      }),
    });
    expect(res.status).toBe(201);
    const body = await res.json();
    expect(body.success).toBe(true);
  });

  test('WebSocket messaging and history', async () => {
    const ws1 = new WebSocket('ws://localhost:8086/chat/ws?roomId=test-room-123&userId=driver-id-abc');

    const historyPromise = new Promise<any>((resolve) => {
      ws1.onmessage = (event) => {
        const data = JSON.parse(event.data.toString());
        if (data.type === 'history') {
          resolve(data);
        }
      };
    });

    const openPromise = new Promise<void>((resolve) => {
      ws1.onopen = () => resolve();
    });

    await openPromise;
    const history = await historyPromise;
    expect(history.messages).toBeDefined();
    expect(Array.isArray(history.messages)).toBe(true);

    const ws2 = new WebSocket('ws://localhost:8086/chat/ws?roomId=test-room-123&userId=passenger-id-xyz');
    const ws2Open = new Promise<void>((resolve) => {
      ws2.onopen = () => resolve();
    });
    await ws2Open;

    const msgPromise = new Promise<any>((resolve) => {
      ws2.onmessage = (event) => {
        const data = JSON.parse(event.data.toString());
        if (data.type === 'message') {
          resolve(data);
        }
      };
    });

    ws1.send(JSON.stringify({ text: 'Hello Passenger!' }));
    const received = await msgPromise;
    expect(received.text).toBe('Hello Passenger!');
    expect(received.senderId).toBe('driver-id-abc');

    ws1.close();
    ws2.close();
  });
});

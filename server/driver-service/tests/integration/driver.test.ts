import { expect, test, describe, beforeAll, afterAll } from 'bun:test';
import { app } from '../../src/index.ts';
import { db } from '../../src/shared/drizzle.ts';
import { drivers, reviews } from '../../src/db/schema.ts';

let driverId = '';

beforeAll(async () => {
  try {
    await db.delete(reviews);
    await db.delete(drivers);
  } catch (e) {
    console.error('Failed to clean driver database:', e);
  }
});

afterAll(async () => {
  try {
    await db.delete(reviews);
    await db.delete(drivers);
  } catch (e) {
    console.error('Failed to clean driver database after tests:', e);
  }
});

describe('Driver Service Integration Tests', () => {
  test('POST /drivers/signup — registers a new driver', async () => {
    const res = await app.request('/drivers/signup', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Test Driver',
        email: 'driver@test.com',
        phone: '09111111111',
        vehicleType: 'Bao Bao',
        plateNumber: 'XYZ 9999',
        password: '@Democrito111',
      }),
    });

    expect(res.status).toBe(201);
    const data: any = await res.json();
    expect(data.id).toBeDefined();
    expect(data.email).toBeDefined();
    expect(data.passwordHash).toBeUndefined();
    driverId = data.id;
  });

  test('POST /drivers/signup — rejects duplicate email', async () => {
    const email = `dup_${Date.now()}@test.com`;
    await app.request('/drivers/signup', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Dup Driver',
        email,
        phone: '09111111112',
        vehicleType: 'Bao Bao',
        plateNumber: 'DUP 0001',
        password: 'password123',
      }),
    });

    const res = await app.request('/drivers/signup', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Dup Driver 2',
        email,
        phone: '09111111113',
        vehicleType: 'Bao Bao',
        plateNumber: 'DUP 0002',
        password: 'password123',
      }),
    });

    expect(res.status).toBe(409);
  });

  test('POST /drivers/login — authenticates with correct password', async () => {
    const email = `login_${Date.now()}@test.com`;
    await app.request('/drivers/signup', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Login Driver',
        email,
        phone: '09222222222',
        vehicleType: 'Bao Bao',
        plateNumber: 'LGN 1234',
        password: 'secret999_password',
      }),
    });

    const res = await app.request('/drivers/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password: 'secret999_password' }),
    });

    expect(res.status).toBe(200);
    const data: any = await res.json();
    expect(data.driver.email).toBe(email);
    expect(data.driver.passwordHash).toBeUndefined();
  });

  test('POST /drivers/login — rejects wrong password', async () => {
    const email = `wrongpass_${Date.now()}@test.com`;
    await app.request('/drivers/signup', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'WP Driver',
        email,
        phone: '09333333333',
        vehicleType: 'Bao Bao',
        plateNumber: 'WP 0001',
        password: 'correctpass_123',
      }),
    });

    const res = await app.request('/drivers/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password: 'wrongpass' }),
    });

    expect(res.status).toBe(401);
  });

  test('POST /drivers/:id/online — sets driver online with coordinates', async () => {
    const res = await app.request(`/drivers/${driverId}/online`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ isOnline: true, lat: 7.828282, lng: 123.434343 }),
    });

    expect(res.status).toBe(200);
    const data: any = await res.json();
    expect(data.isOnline).toBe(true);
    expect(data.lat).toBe(7.828282);
  });

  test('GET /drivers/online — lists online drivers without passwordHash', async () => {
    const res = await app.request('/drivers/online');
    expect(res.status).toBe(200);
    const data: any = await res.json();
    expect(Array.isArray(data)).toBe(true);
    expect(data.length).toBeGreaterThan(0);
    expect(data[0].passwordHash).toBeUndefined();
  });

  test('GET /drivers/:id/reviews — retrieves driver reviews', async () => {
    await db.insert(reviews).values([
      {
        id: crypto.randomUUID(),
        driverId,
        passengerName: 'Aria Cruz',
        rating: 5.0,
        comment: 'Highly recommend! Very pleasant conversation and smooth driving.',
        createdAt: new Date('2026-07-07T12:00:00Z'),
      },
      {
        id: crypto.randomUUID(),
        driverId,
        passengerName: 'Carlos Diaz',
        rating: 4.9,
        comment: 'Excellent service. Helped me with my heavy bags.',
        createdAt: new Date('2026-07-05T12:00:00Z'),
      },
      {
        id: crypto.randomUUID(),
        driverId,
        passengerName: 'Sophia Lim',
        rating: 5.0,
        comment: 'Punctual and very respectful driver. The Bao was in top condition.',
        createdAt: new Date('2026-07-03T12:00:00Z'),
      },
      {
        id: crypto.randomUUID(),
        driverId,
        passengerName: 'Maria Santos',
        rating: 5.0,
        comment: 'Amazing ride! The vehicle was extremely clean, and the driver was polite and punctual.',
        createdAt: new Date('2026-07-01T12:00:00Z'),
      },
    ]);

    const res = await app.request(`/drivers/${driverId}/reviews`);
    expect(res.status).toBe(200);
    const data: any = await res.json();
    expect(Array.isArray(data)).toBe(true);
    expect(data.length).toBe(4);
    expect(data[0].passengerName).toBe('Aria Cruz');
  });
});

import { expect, test, describe, beforeAll } from 'bun:test';
import driverApp from '../src/index.ts';
import { prisma } from '../src/db.ts';

let driverId = '';

beforeAll(async () => {
  try {
    await prisma.driver.deleteMany();
  } catch (e) {
    console.error('Failed to clean driver database:', e);
  }
});

describe('Driver Service', () => {
  test('POST /drivers/signup — registers a new driver', async () => {
    const res = await driverApp.fetch(
      new Request('http://localhost/drivers/signup', {
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
      })
    );
    expect(res.status).toBe(201);
    const data: any = await res.json();
    expect(data.id).toBeDefined();
    expect(data.email).toBeDefined();
    expect(data.passwordHash).toBeUndefined();
    driverId = data.id;
  });

  test('POST /drivers/signup — rejects duplicate email', async () => {
    const email = `dup_${Date.now()}@test.com`;
    await driverApp.fetch(
      new Request('http://localhost/drivers/signup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: 'Dup Driver', email, phone: '09111111112',
          vehicleType: 'Bao Bao', plateNumber: 'DUP 0001', password: 'pass',
        }),
      })
    );
    const res = await driverApp.fetch(
      new Request('http://localhost/drivers/signup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: 'Dup Driver 2', email, phone: '09111111113',
          vehicleType: 'Bao Bao', plateNumber: 'DUP 0002', password: 'pass',
        }),
      })
    );
    expect(res.status).toBe(409);
  });

  test('POST /drivers/login — authenticates with correct password', async () => {
    const email = `login_${Date.now()}@test.com`;
    await driverApp.fetch(
      new Request('http://localhost/drivers/signup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: 'Login Driver', email, phone: '09222222222',
          vehicleType: 'Bao Bao', plateNumber: 'LGN 1234', password: 'secret999',
        }),
      })
    );
    const res = await driverApp.fetch(
      new Request('http://localhost/drivers/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password: 'secret999' }),
      })
    );
    expect(res.status).toBe(200);
    const data: any = await res.json();
    expect(data.driver.email).toBe(email);
    expect(data.driver.passwordHash).toBeUndefined();
  });

  test('POST /drivers/login — rejects wrong password', async () => {
    const email = `wrongpass_${Date.now()}@test.com`;
    await driverApp.fetch(
      new Request('http://localhost/drivers/signup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: 'WP Driver', email, phone: '09333333333',
          vehicleType: 'Bao Bao', plateNumber: 'WP 0001', password: 'correctpass',
        }),
      })
    );
    const res = await driverApp.fetch(
      new Request('http://localhost/drivers/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password: 'wrongpass' }),
      })
    );
    expect(res.status).toBe(401);
  });

  test('POST /drivers/:id/online — sets driver online with coordinates', async () => {
    const res = await driverApp.fetch(
      new Request(`http://localhost/drivers/${driverId}/online`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ isOnline: true, lat: 7.828282, lng: 123.434343 }),
      })
    );
    expect(res.status).toBe(200);
    const data: any = await res.json();
    expect(data.isOnline).toBe(true);
    expect(data.lat).toBe(7.828282);
  });

  test('GET /drivers/online — lists online drivers without passwordHash', async () => {
    const res = await driverApp.fetch(new Request('http://localhost/drivers/online'));
    expect(res.status).toBe(200);
    const data: any = await res.json();
    expect(Array.isArray(data)).toBe(true);
    expect(data.length).toBeGreaterThan(0);
    expect(data[0].passwordHash).toBeUndefined();
  });
});

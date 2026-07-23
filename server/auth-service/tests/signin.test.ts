import { describe, expect, test } from 'bun:test';
import { app } from '../src/index.ts';

process.env.JWT_SECRET = 'test_environment_jwt_secret_key_12345';

describe('Auth Service — Sign In Integration Tests', () => {
  test('POST /auth/passenger/login — authenticates registered passenger with valid credentials', async () => {
    await app.request('/auth/passenger/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Charlie Passenger',
        email: 'charlie.passenger@example.com',
        phone: '+639170000004',
        password: 'loginPassword123',
        preferred_ride_type: 'solo-ride',
      }),
    });

    const res = await app.request('/auth/passenger/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'charlie.passenger@example.com',
        password: 'loginPassword123',
      }),
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(body.data.token).toBeDefined();
    expect(body.data.user.email).toBe('charlie.passenger@example.com');
  });

  test('POST /auth/driver/login — authenticates registered driver with valid credentials', async () => {
    await app.request('/auth/driver/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Dave Driver',
        email: 'dave.driver@example.com',
        phone: '+639170000005',
        password: 'driverPassword123',
        vehicleType: 'Tricycle',
        plateNumber: 'ABC 1234',
      }),
    });

    const res = await app.request('/auth/driver/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'dave.driver@example.com',
        password: 'driverPassword123',
      }),
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(body.data.token).toBeDefined();
    expect(body.data.user.email).toBe('dave.driver@example.com');
  });

  test('POST /auth/passenger/login — fails with wrong password', async () => {
    const res = await app.request('/auth/passenger/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'charlie.passenger@example.com',
        password: 'wrongPassword123',
      }),
    });
    expect(res.status).toBe(401);
  });

  test('POST /auth/passenger/login — rejects non-existent email address', async () => {
    const res = await app.request('/auth/passenger/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'nonexistent.passenger@example.com',
        password: 'somePassword123',
      }),
    });
    expect(res.status).toBe(401);
  });
});

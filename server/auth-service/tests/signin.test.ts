import { describe, expect, test } from 'bun:test';
import { app } from '../src/index.ts';

process.env.JWT_SECRET = 'test_environment_jwt_secret_key_12345';
process.env.EMAIL_DELIVERY_DISABLED = 'true';

const testRunId = crypto.randomUUID().slice(0, 8);
const passengerEmail = `charlie.passenger.${testRunId}@example.test`;
const driverEmail = `dave.driver.${testRunId}@example.test`;

describe('Auth Service — Sign In Integration Tests', () => {
  test('POST /auth/passenger/login — authenticates registered passenger with valid credentials', async () => {
    await app.request('/auth/passenger/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Charlie Passenger',
        email: passengerEmail,
        phone: `+63919${testRunId.replace(/\D/g, '').padEnd(7, '0').slice(0, 7)}`,
        password: 'loginPassword123',
        preferred_ride_type: 'solo-ride',
      }),
    });

    const res = await app.request('/auth/passenger/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: passengerEmail,
        password: 'loginPassword123',
      }),
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(body.data.token).toBeDefined();
    expect(body.data.user.email).toBe(passengerEmail);
  });

  test('POST /auth/driver/login — authenticates registered driver with valid credentials', async () => {
    await app.request('/auth/driver/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Dave Driver',
        email: driverEmail,
        phone: `+63916${testRunId.replace(/\D/g, '').padEnd(7, '0').slice(0, 7)}`,
        password: 'driverPassword123',
        vehicleType: 'Tricycle',
        plateNumber: `TEST-${testRunId}`,
      }),
    });

    const res = await app.request('/auth/driver/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: driverEmail,
        password: 'driverPassword123',
      }),
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(body.data.token).toBeDefined();
    expect(body.data.user.email).toBe(driverEmail);
  });

  test('POST /auth/passenger/login — fails with wrong password', async () => {
    const res = await app.request('/auth/passenger/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: passengerEmail,
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

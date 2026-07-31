import { describe, expect, test } from 'bun:test';
import { app } from '../src/index.ts';

process.env.JWT_SECRET = 'test_environment_jwt_secret_key_12345';
process.env.EMAIL_DELIVERY_DISABLED = 'true';

const testRunId = crypto.randomUUID().slice(0, 8);
const passengerEmail = `alice.passenger.${testRunId}@example.test`;
const driverEmail = `bob.driver.${testRunId}@example.test`;

describe('Auth Service — Sign Up Integration Tests', () => {
  test('POST /auth/passenger/register — successfully registers a new passenger with preferred ride type', async () => {
    const res = await app.request('/auth/passenger/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Alice Passenger',
        email: passengerEmail,
        phone: `+63917${testRunId.replace(/\D/g, '').padEnd(7, '0').slice(0, 7)}`,
        password: 'securePassword123',
        preferred_ride_type: 'solo-ride',
      }),
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(body.data.token).toBeDefined();
    expect(body.data.user.email).toBe(passengerEmail);
    expect(body.data.user.role).toBe('passenger');
    expect(body.data.user.preferred_ride_type).toBe('solo-ride');
    expect(body.data.user.passwordHash).toBeUndefined();
    expect(body.data.needsVerification).toBe(true);
  });

  test('POST /auth/driver/register — successfully registers a new driver with vehicle details', async () => {
    const res = await app.request('/auth/driver/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Bob Driver',
        email: driverEmail,
        phone: `+63918${testRunId.replace(/\D/g, '').padEnd(7, '0').slice(0, 7)}`,
        password: 'driverPassword123',
        vehicleType: 'Tricycle',
        plateNumber: `TEST-${testRunId}`,
      }),
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(body.data.token).toBeDefined();
    expect(body.data.user.email).toBe(driverEmail);
    expect(body.data.user.role).toBe('driver');
    expect(body.data.user.vehicleType).toBe('Tricycle');
    expect(body.data.user.plateNumber).toBe(`TEST-${testRunId}`);
    expect(body.data.user.rating).toBe(5.0);
    expect(body.data.needsVerification).toBe(true);
  });

  test('POST /auth/passenger/register — fails when registering existing email', async () => {
    const res = await app.request('/auth/passenger/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Duplicate Passenger',
        email: passengerEmail,
        phone: `+63917${testRunId.replace(/\D/g, '').padEnd(7, '0').slice(0, 7)}`,
        password: 'anotherPassword123',
        preferred_ride_type: 'solo-ride',
      }),
    });
    expect(res.status).toBe(400);
  });

  test('POST /auth/passenger/register — fails schema validation on short password', async () => {
    const res = await app.request('/auth/passenger/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Short Pass User',
        email: 'shortpass@example.com',
        phone: '+639170000003',
        password: '123',
        preferred_ride_type: 'solo-ride',
      }),
    });
    expect(res.status).toBe(400);
  });
});

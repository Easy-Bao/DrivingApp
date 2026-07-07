import { expect, test, describe } from 'bun:test';
import { Hono } from 'hono';
import { getPassengerRouter } from '../src/passenger/routes.ts';
import { InMemoryPassengerRepository } from '../src/passenger/index.ts';

describe('Passenger Account Endpoints', () => {
  const repo = new InMemoryPassengerRepository();
  const app = new Hono();
  app.route('/', getPassengerRouter(repo));

  let passengerId = '';

  test('POST /passengers - creates passenger successfully', async () => {
    const res = await app.request('/passengers', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Test User',
        email: 'test@example.com',
        phone: '1234567890',
        password: 'password123',
        preferred_ride_type: 'solo-ride',
      }),
    });

    expect(res.status).toBe(201);
    const data: any = await res.json();
    expect(data.needs_verification).toBe(true);
    expect(data.email).toBe('test@example.com');
    expect(data.passenger.id).toBeDefined();
    expect(data.passenger.name).toBe('Test User');
    expect(data.passenger.email).toBe('test@example.com');
    expect(data.passenger.password_hash).toBeUndefined();

    passengerId = data.passenger.id;
  });

  test('POST /passengers/verify-otp - verifies passenger successfully', async () => {
    const res = await app.request('/passengers/verify-otp', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'test@example.com',
        code: '123456',
      }),
    });

    expect(res.status).toBe(200);
    const data: any = await res.json();
    expect(data.success).toBe(true);
  });

  test('POST /passengers/login - authenticates passenger and returns token', async () => {
    const res = await app.request('/passengers/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'test@example.com',
        password: 'password123',
      }),
    });

    expect(res.status).toBe(200);
    const data: any = await res.json();
    expect(data.token).toBeDefined();
    expect(data.passenger.id).toBeDefined();
  });

  test('GET /passengers/:id - retrieves passenger profile', async () => {
    const res = await app.request(`/passengers/${passengerId}`);

    expect(res.status).toBe(200);
    const data: any = await res.json();
    expect(data.id).toBe(passengerId);
    expect(data.name).toBe('Test User');
  });

  test('PUT /passengers/:id - updates passenger profile', async () => {
    const res = await app.request(`/passengers/${passengerId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Updated User Name',
        phone: '9999999999',
        email: 'test@example.com',
      }),
    });

    expect(res.status).toBe(200);
    const data: any = await res.json();
    expect(data.id).toBe(passengerId);
    expect(data.name).toBe('Updated User Name');
    expect(data.phone).toBe('9999999999');
  });

  test('POST /passengers/forgot-password - triggers password recovery email', async () => {
    const res = await app.request('/passengers/forgot-password', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'test@example.com',
      }),
    });

    expect(res.status).toBe(200);
    const data: any = await res.json();
    expect(data.success).toBe(true);
  });
});

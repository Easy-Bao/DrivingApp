/**
 * Server unit tests: defines a test suite verifying Hono API routing, payload validation, passenger creation, login authentication, and ride request endpoints.
 */
import { expect, test, describe } from 'bun:test';
import { Hono } from 'hono';
import { getPassengerRouter } from '../src/passenger/routes.ts';
import { InMemoryPassengerRepository } from '../src/passenger/repository.ts';

describe('Passenger Service Endpoints', () => {
  const repo = new InMemoryPassengerRepository();
  const app = new Hono();
  app.route('/', getPassengerRouter(repo));

  let passengerId = '';
  let token = '';

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
    expect(data.passenger.id).toBe(passengerId);

    token = data.token;
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

  test('POST /rides - requests a ride successfully', async () => {
    const res = await app.request('/rides', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        passenger_id: passengerId,
        ride_type: 'solo-ride',
        pickup_latitude: 7.8286,
        pickup_longitude: 123.4361,
        pickup_name: 'Plaza Luz',
        dropoff_latitude: 7.8250,
        dropoff_longitude: 123.4380,
        dropoff_name: 'Robinson Supermarket',
        fare: 150.0,
      }),
    });

    expect(res.status).toBe(201);
    const data: any = await res.json();
    expect(data.id).toBeDefined();
    expect(data.passenger_id).toBe(passengerId);
    expect(data.status).toBe('requested');
  });

  test('GET /passengers/:id/rides - lists all rides for passenger', async () => {
    const res = await app.request(`/passengers/${passengerId}/rides`);

    expect(res.status).toBe(200);
    const data: any = await res.json();
    expect(Array.isArray(data)).toBe(true);
    expect(data.length).toBe(1);
    expect(data[0].pickup_name).toBe('Plaza Luz');
  });
});

import { expect, test, describe } from 'bun:test';
import { Hono } from 'hono';
import { getPassengerRouter } from '../src/passenger/routes.ts';
import { InMemoryPassengerRepository } from '../src/passenger/index.ts';

describe('Ride Request & Notification Endpoints', () => {
  const repo = new InMemoryPassengerRepository();
  const app = new Hono();
  app.route('/', getPassengerRouter(repo));

  let passengerId = '';

  test('POST /rides - requests a ride successfully', async () => {
    const pRes = await app.request('/passengers', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Rider User',
        email: 'rider@example.com',
        phone: '1111111111',
        password: 'password123',
        preferred_ride_type: 'solo-ride',
      }),
    });
    const pData: any = await pRes.json();
    passengerId = pData.passenger.id;

    await app.request('/passengers/verify-otp', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'rider@example.com',
        code: '123456',
      }),
    });

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

  test('GET /passengers/:id/notifications - retrieves passenger notifications', async () => {
    const res = await app.request(`/passengers/${passengerId}/notifications`);

    expect(res.status).toBe(200);
    const data: any = await res.json();
    expect(Array.isArray(data)).toBe(true);
    expect(data.length).toBeGreaterThan(0);
  });
});

import { expect, test, describe, spyOn, beforeAll, afterAll } from 'bun:test';
import { app } from '../../src/index.ts';
import { db } from '../../src/shared/drizzle.ts';
import { rides } from '../../src/db/schema.ts';

const TEST_PASSENGER_ID = crypto.randomUUID();
let rideId = '';

describe('Trip Service Integration Tests', () => {
  beforeAll(async () => {
    spyOn(global, 'fetch').mockResolvedValue(
      new Response(JSON.stringify({ name: 'Test User' }), { status: 200 })
    );
    await db.delete(rides);
  });

  afterAll(() => {
    global.fetch = typeof global.fetch === 'function' ? global.fetch : fetch;
  });

  test('POST /rides — creates a ride request', async () => {
    const res = await app.request('/rides', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        passenger_id: TEST_PASSENGER_ID,
        ride_type: 'solo-ride',
        pickup_latitude: 7.828282,
        pickup_longitude: 123.434343,
        pickup_name: 'City Hall, Pagadian City',
        dropoff_latitude: 7.830000,
        dropoff_longitude: 123.436000,
        dropoff_name: 'Robinson Supermarket, Pagadian City',
        fare: 52.0,
      }),
    });

    expect(res.status).toBe(201);
    const data: any = await res.json();
    expect(data.id).toBeDefined();
    expect(data.status).toBe('requested');
    expect(data.fare).toBe(52.0);
    rideId = data.id;
  });

  test('GET /rides/active — returns pending ride requests', async () => {
    const res = await app.request('/rides/active');
    expect(res.status).toBe(200);
    const data: any = await res.json();
    expect(Array.isArray(data)).toBe(true);
    expect(data.some((r: any) => r.id === rideId)).toBe(true);
  });

  test('GET /rides/:id — retrieves a specific ride', async () => {
    const res = await app.request(`/rides/${rideId}`);
    expect(res.status).toBe(200);
    const data: any = await res.json();
    expect(data.id).toBe(rideId);
    expect(data.status).toBe('requested');
  });

  test('POST /rides/:id/accept — assigns driver to ride', async () => {
    const res = await app.request(`/rides/${rideId}/accept`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        driver_id: 'driver-test-id',
        driver_name: 'Test Driver',
        driver_rating: '4.8',
        vehicle_type: 'Bao Bao',
        plate_number: 'TST 0001',
      }),
    });

    expect(res.status).toBe(200);
    const data: any = await res.json();
    expect(data.status).toBe('accepted');
    expect(data.driver_name).toBe('Test Driver');
    expect(data.driver_id).toBe('driver-test-id');
  });

  test('POST /rides/:id/status — transitions through arrived and in_transit', async () => {
    for (const status of ['arrived', 'in_transit']) {
      const res = await app.request(`/rides/${rideId}/status`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status }),
      });
      expect(res.status).toBe(200);
      const data: any = await res.json();
      expect(data.status).toBe(status);
    }
  });

  test('POST /rides/:id/status — completed removes from active list', async () => {
    const res = await app.request(`/rides/${rideId}/status`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status: 'completed' }),
    });

    expect(res.status).toBe(200);
    const activeRes = await app.request('/rides/active');
    const active: any = await activeRes.json();
    expect(active.some((r: any) => r.id === rideId)).toBe(false);
  });
});

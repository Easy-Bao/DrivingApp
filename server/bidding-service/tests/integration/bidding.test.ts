import { expect, test, describe, beforeAll } from 'bun:test';
import { app } from '../../src/index.ts';
import { db } from '../../src/shared/drizzle.ts';
import { bidSessions, driverOffers } from '../../src/db/schema.ts';
import { sign } from 'hono/jwt';

const TEST_PASSENGER_ID = '00000000-0000-0000-0000-000000000001';
let sessionId = '';
let offerId = '';
let passengerToken = '';
let driverOneToken = '';
let driverTwoToken = '';

interface FareResponse {
  base_fare: number;
  total_fare: number;
}

interface BidSessionResponse {
  id: string;
  status: string;
  offered_fare: number;
}

interface DriverOfferResponse {
  id: string;
  driver_id: string;
  proposed_fare: number;
}

describe('Bidding Service Integration Tests', () => {
  beforeAll(async () => {
    const secret = process.env.JWT_SECRET!;
    passengerToken = await sign({
      sub: TEST_PASSENGER_ID,
      role: 'passenger',
      exp: Math.floor(Date.now() / 1000) + 300,
    }, secret);
    driverOneToken = await sign({
      sub: 'driver-test-1',
      role: 'driver',
      exp: Math.floor(Date.now() / 1000) + 300,
    }, secret);
    driverTwoToken = await sign({
      sub: 'driver-test-2',
      role: 'driver',
      exp: Math.floor(Date.now() / 1000) + 300,
    }, secret);
    try {
      await db.delete(driverOffers);
      await db.delete(bidSessions);
    } catch (e) {
      console.error('Failed to clean database:', e);
    }
  });

  test('POST /bids/fare — calculates fare correctly', async () => {
    const res = await app.request('/bids/fare', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${passengerToken}`,
      },
      body: JSON.stringify({
        ride_type: 'Solo Ride',
        distance_km: 5.0,
        duration_minutes: 10.0,
      }),
    });

    expect(res.status).toBe(200);
    const data = (await res.json()) as FareResponse;
    expect(data.base_fare).toBe(20.0);
    expect(data.total_fare).toBe(85.0);
  });

  test('POST /bids — opens a bid session', async () => {
    const res = await app.request('/bids', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${passengerToken}`,
      },
      body: JSON.stringify({
        passenger_id: TEST_PASSENGER_ID,
        ride_type: 'Solo Ride',
        pickup_latitude: 7.828282,
        pickup_longitude: 123.434343,
        pickup_name: 'City Hall',
        dropoff_latitude: 7.830000,
        dropoff_longitude: 123.436000,
        dropoff_name: 'Robinson Supermarket',
        distance_km: 5.0,
        duration_minutes: 10.0,
      }),
    });

    expect(res.status).toBe(201);
    const data = (await res.json()) as BidSessionResponse;
    expect(data.id).toBeDefined();
    expect(data.status).toBe('open');
    expect(data.offered_fare).toBe(85.0);
    sessionId = data.id;
  });

  test('GET /bids/active — lists active sessions', async () => {
    const res = await app.request('/bids/active', {
      headers: { Authorization: `Bearer ${driverOneToken}` },
    });
    expect(res.status).toBe(200);
    const data = (await res.json()) as BidSessionResponse[];
    expect(Array.isArray(data)).toBe(true);
    expect(data.some((s) => s.id === sessionId)).toBe(true);
  });

  test('POST /bids/:id/offer — places a driver bid', async () => {
    const res = await app.request(`/bids/${sessionId}/offer`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${driverOneToken}`,
      },
      body: JSON.stringify({
        proposed_fare: 90.0,
      }),
    });

    expect(res.status).toBe(201);
    const data = (await res.json()) as DriverOfferResponse;
    expect(data.id).toBeDefined();
    expect(data.driver_id).toBe('driver-test-1');
    expect(data.proposed_fare).toBe(90.0);
    offerId = data.id;
  });

  test('GET /bids/:id/offers — lists pending offers for session', async () => {
    const res = await app.request(`/bids/${sessionId}/offers`, {
      headers: { Authorization: `Bearer ${passengerToken}` },
    });
    expect(res.status).toBe(200);
    const data = (await res.json()) as DriverOfferResponse[];
    expect(Array.isArray(data)).toBe(true);
    expect(data.length).toBe(1);
    expect(data[0].id).toBe(offerId);
  });

  test('POST /bids/:id/cancel-offer — driver withdraws offer', async () => {
    const resOffer = await app.request(`/bids/${sessionId}/offer`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${driverTwoToken}`,
      },
      body: JSON.stringify({
        proposed_fare: 85.0,
      }),
    });
    expect(resOffer.status).toBe(201);

    const resCancel = await app.request(`/bids/${sessionId}/cancel-offer`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${driverTwoToken}` },
    });
    expect(resCancel.status).toBe(200);

    const resOffers = await app.request(`/bids/${sessionId}/offers`, {
      headers: { Authorization: `Bearer ${passengerToken}` },
    });
    const data = (await resOffers.json()) as DriverOfferResponse[];
    expect(data.some((o) => o.driver_id === 'driver-test-2')).toBe(false);
  });
});

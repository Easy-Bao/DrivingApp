import { expect, test, describe, beforeAll } from 'bun:test';
import { app } from '../../src/index.ts';
import { db } from '../../src/shared/drizzle.ts';
import { bidSessions, driverOffers } from '../../src/db/schema.ts';

const TEST_PASSENGER_ID = '00000000-0000-0000-0000-000000000001';
let sessionId = '';
let offerId = '';

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
      headers: { 'Content-Type': 'application/json' },
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
      headers: { 'Content-Type': 'application/json' },
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
    const res = await app.request('/bids/active');
    expect(res.status).toBe(200);
    const data = (await res.json()) as BidSessionResponse[];
    expect(Array.isArray(data)).toBe(true);
    expect(data.some((s) => s.id === sessionId)).toBe(true);
  });

  test('POST /bids/:id/offer — places a driver bid', async () => {
    const res = await app.request(`/bids/${sessionId}/offer`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        driver_id: 'driver-test-1',
        driver_name: 'Bid Driver',
        plate_number: 'BID 123',
        vehicle_type: 'Bao Bao',
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
    const res = await app.request(`/bids/${sessionId}/offers`);
    expect(res.status).toBe(200);
    const data = (await res.json()) as DriverOfferResponse[];
    expect(Array.isArray(data)).toBe(true);
    expect(data.length).toBe(1);
    expect(data[0].id).toBe(offerId);
  });

  test('POST /bids/:id/cancel-offer — driver withdraws offer', async () => {
    const resOffer = await app.request(`/bids/${sessionId}/offer`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        driver_id: 'driver-test-2',
        driver_name: 'Bid Driver 2',
        plate_number: 'BID 456',
        vehicle_type: 'Bao Bao',
        proposed_fare: 85.0,
      }),
    });
    expect(resOffer.status).toBe(201);

    const resCancel = await app.request(`/bids/${sessionId}/cancel-offer`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        driver_id: 'driver-test-2',
      }),
    });
    expect(resCancel.status).toBe(200);

    const resOffers = await app.request(`/bids/${sessionId}/offers`);
    const data = (await resOffers.json()) as DriverOfferResponse[];
    expect(data.some((o) => o.driver_id === 'driver-test-2')).toBe(false);
  });
});

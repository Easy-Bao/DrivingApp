/// Bidding service unit tests: verifies fare calculation, bid session creation, active listings, driver bidding, and acceptance.
import { expect, test, describe } from 'bun:test';
import biddingApp from '../src/index.ts';

const TEST_PASSENGER_ID = '00000000-0000-0000-0000-000000000001';
let sessionId = '';
let offerId = '';

describe('Bidding Service', () => {
  test('POST /bids/fare — calculates fare correctly', async () => {
    const res = await biddingApp.fetch(
      new Request('http://localhost/bids/fare', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ride_type: 'Solo Ride',
          distance_km: 5.0,
          duration_minutes: 10.0,
        }),
      })
    );
    expect(res.status).toBe(200);
    const data: any = await res.json();
    expect(data.base_fare).toBe(20.0);
    expect(data.total_fare).toBe(85.0); // 20 + 5*10 + 10*1.5 = 20 + 50 + 15 = 85
  });

  test('POST /bids — opens a bid session', async () => {
    const res = await biddingApp.fetch(
      new Request('http://localhost/bids', {
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
      })
    );
    expect(res.status).toBe(201);
    const data: any = await res.json();
    expect(data.id).toBeDefined();
    expect(data.status).toBe('open');
    expect(data.offered_fare).toBe(85.0);
    sessionId = data.id;
  });

  test('GET /bids/active — lists active sessions', async () => {
    const res = await biddingApp.fetch(
      new Request('http://localhost/bids/active')
    );
    expect(res.status).toBe(200);
    const data: any = await res.json();
    expect(Array.isArray(data)).toBe(true);
    expect(data.some((s: any) => s.id === sessionId)).toBe(true);
  });

  test('POST /bids/:id/offer — places a driver bid', async () => {
    const res = await biddingApp.fetch(
      new Request(`http://localhost/bids/${sessionId}/offer`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          driver_id: 'driver-test-1',
          driver_name: 'Bid Driver',
          plate_number: 'BID 123',
          vehicle_type: 'Bao Bao',
          proposed_fare: 90.0,
        }),
      })
    );
    expect(res.status).toBe(201);
    const data: any = await res.json();
    expect(data.id).toBeDefined();
    expect(data.driver_id).toBe('driver-test-1');
    expect(data.proposed_fare).toBe(90.0);
    offerId = data.id;
  });

  test('GET /bids/:id/offers — lists pending offers for session', async () => {
    const res = await biddingApp.fetch(
      new Request(`http://localhost/bids/${sessionId}/offers`)
    );
    expect(res.status).toBe(200);
    const data: any = await res.json();
    expect(Array.isArray(data)).toBe(true);
    expect(data.length).toBe(1);
    expect(data[0].id).toBe(offerId);
  });

  test('POST /bids/:id/cancel-offer — driver withdraws offer', async () => {
    // Submit a second offer
    const resOffer = await biddingApp.fetch(
      new Request(`http://localhost/bids/${sessionId}/offer`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          driver_id: 'driver-test-2',
          driver_name: 'Bid Driver 2',
          plate_number: 'BID 456',
          vehicle_type: 'Bao Bao',
          proposed_fare: 85.0,
        }),
      })
    );
    expect(resOffer.status).toBe(201);

    // Cancel it
    const resCancel = await biddingApp.fetch(
      new Request(`http://localhost/bids/${sessionId}/cancel-offer`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          driver_id: 'driver-test-2',
        }),
      })
    );
    expect(resCancel.status).toBe(200);

    // Verify it is not in the pending offers list
    const resOffers = await biddingApp.fetch(
      new Request(`http://localhost/bids/${sessionId}/offers`)
    );
    const data = await resOffers.json() as any[];
    expect(data.some((o: any) => o.driver_id === 'driver-test-2')).toBe(false);
  });
});

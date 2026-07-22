import { expect, test, describe } from 'bun:test';
import { app } from '../../src/index.ts';

describe('Fare Service Integration Tests', () => {
  test('GET /fares/configs — returns active pricing configurations from backend authority', async () => {
    const res = await app.request('/fares/configs');
    expect(res.status).toBe(200);
    const data = await res.json();
    expect(data.success).toBe(true);
    expect(data.data.length).toBeGreaterThanOrEqual(3);
  });

  test('POST /fares/estimate — returns estimates for all service types', async () => {
    const res = await app.request('/fares/estimate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        distanceKm: 5.2,
        durationMinutes: 15.0,
      }),
    });

    expect(res.status).toBe(200);
    const data = await res.json();
    expect(data.success).toBe(true);
    expect(data.data.currency).toBe('PHP');
    expect(data.data.estimates.length).toBeGreaterThanOrEqual(3);
  });

  test('POST /fares/calculate-final — computes binding fare & driver split', async () => {
    const res = await app.request('/fares/calculate-final', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        rideId: 'test-ride-123',
        distanceKm: 10.0,
        durationMinutes: 20.0,
        rideType: 'Solo Ride',
        surgeMultiplier: 1.0,
      }),
    });

    expect(res.status).toBe(200);
    const data = await res.json();
    expect(data.success).toBe(true);
    expect(data.data.ride_id).toBe('test-ride-123');
    expect(data.data.total_fare).toBe(150.0);
    expect(data.data.driver_earnings).toBe(120.0);
    expect(data.data.platform_fee).toBe(30.0);
  });
});

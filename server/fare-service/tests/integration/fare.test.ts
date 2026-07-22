import { expect, test, describe, beforeAll, spyOn } from 'bun:test';
import { app } from '../../src/index.ts';
import { PricingConfigService } from '../../src/features/services/pricing_config.service.ts';
import { FareCalculationService } from '../../src/features/services/fare_calculation.service.ts';

describe('Fare Service Integration Tests', () => {
  beforeAll(() => {
    spyOn(PricingConfigService.prototype, 'getPricingConfigs').mockImplementation(async () => [
      { id: '1', serviceType: 'Solo Ride', baseFare: 20.0, perKmRate: 10.0, perMinuteRate: 1.5, minimumFare: 25.0, surgeMultiplier: 1.0, isActive: true },
      { id: '2', serviceType: 'Share-Bao', baseFare: 15.0, perKmRate: 7.0, perMinuteRate: 1.0, minimumFare: 20.0, surgeMultiplier: 1.0, isActive: true },
      { id: '3', serviceType: 'Bao Premium', baseFare: 35.0, perKmRate: 15.0, perMinuteRate: 2.0, minimumFare: 40.0, surgeMultiplier: 1.0, isActive: true },
    ]);

    spyOn(PricingConfigService.prototype, 'getRatingConfig').mockImplementation(async () => ({
      minimumRatingThreshold: 4.5,
      highRatingBonusMultiplier: 1.05,
      lowRatingSurgePenaltyMultiplier: 1.0,
      baseSurgeCap: 2.5,
    }));
  });

  test('GET /fares/configs — returns active pricing configurations from backend authority', async () => {
    const res = await app.request('/fares/configs');
    expect(res.status).toBe(200);
    const data = await res.json();
    expect(data.success).toBe(true);
    expect(data.data.length).toBeGreaterThanOrEqual(3);
  });

  test('GET /fares/rating-config — returns rating pricing configuration from database authority', async () => {
    const res = await app.request('/fares/rating-config');
    expect(res.status).toBe(200);
    const data = await res.json();
    expect(data.success).toBe(true);
    expect(data.data.minimumRatingThreshold).toBe(4.5);
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
    spyOn(FareCalculationService.prototype, 'calculateFinalFare').mockImplementation(
      async (rideId, distanceKm, durationMinutes, rideType = 'Solo Ride', surgeMultiplier = 1.0) => {
        return {
          rideId,
          ride_id: rideId,
          serviceType: rideType,
          service_type: rideType,
          distanceKm,
          distance_km: distanceKm,
          durationMinutes,
          duration_minutes: durationMinutes,
          baseFare: 20.0,
          base_fare: 20.0,
          distanceCharge: 100.0,
          distance_charge: 100.0,
          timeCharge: 30.0,
          time_charge: 30.0,
          surgeCharge: 0.0,
          surge_charge: 0.0,
          totalFare: 150.0,
          total_fare: 150.0,
          driverEarnings: 120.0,
          driver_earnings: 120.0,
          platformFee: 30.0,
          platform_fee: 30.0,
          paymentMethod: 'Cash on Hand',
          payment_method: 'Cash on Hand',
        };
      },
    );

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

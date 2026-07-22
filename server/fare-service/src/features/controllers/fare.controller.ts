import { Context } from 'hono';
import { FareCalculationService } from '../services/fare_calculation.service.ts';
import { PricingConfigService } from '../services/pricing_config.service.ts';

const fareCalculationService = new FareCalculationService();
const pricingConfigService = new PricingConfigService();

export async function handleGetPricingConfigs(c: Context) {
  const configs = await pricingConfigService.getPricingConfigs();
  return c.json({
    success: true,
    data: configs,
  });
}

export async function handleGetRatingConfig(c: Context) {
  const ratingConfig = await pricingConfigService.getRatingConfig();
  return c.json({
    success: true,
    data: ratingConfig,
  });
}

export async function handleEstimateFares(c: Context) {
  const body = c.req.valid('json' as never) as { distanceKm: number; durationMinutes?: number };
  const result = await fareCalculationService.estimateFares(
    body.distanceKm,
    body.durationMinutes ?? 0.0,
  );
  return c.json({
    success: true,
    data: result,
  });
}

export async function handleCalculateFinalFare(c: Context) {
  const body = c.req.valid('json' as never) as {
    rideId: string;
    distanceKm: number;
    durationMinutes: number;
    rideType?: string;
    surgeMultiplier?: number;
  };
  const result = await fareCalculationService.calculateFinalFare(
    body.rideId,
    body.distanceKm,
    body.durationMinutes,
    body.rideType ?? 'Solo Ride',
    body.surgeMultiplier ?? 1.0,
  );
  return c.json({
    success: true,
    data: result,
  });
}

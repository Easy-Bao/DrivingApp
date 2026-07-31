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
    driverId?: string;
  };
  const result = await fareCalculationService.calculateFinalFare(
    body.rideId,
    body.distanceKm,
    body.durationMinutes,
    body.rideType ?? 'Solo Ride',
    body.surgeMultiplier ?? 1.0,
    body.driverId,
  );
  return c.json({
    success: true,
    data: result,
  });
}

export async function handleAdminGetPricing(c: Context) {
  return c.json(await pricingConfigService.getPricingConfigs());
}

export async function handleAdminUpdatePricing(c: Context) {
  const serviceType = c.req.param('serviceType');
  const body = await c.req.json() as {
    base_fare: number;
    per_km_rate: number;
    per_minute_rate: number;
    minimum_fare: number;
    surge_multiplier: number;
    is_active: boolean;
  };
  return c.json(await pricingConfigService.updatePricingConfig(serviceType!, {
    baseFare: body.base_fare,
    perKmRate: body.per_km_rate,
    perMinuteRate: body.per_minute_rate,
    minimumFare: body.minimum_fare,
    surgeMultiplier: body.surge_multiplier,
    isActive: body.is_active,
  }));
}

export async function handleAdminGetTransactions(c: Context) {
  return c.json(await pricingConfigService.getTransactions({
    status: c.req.query('status'),
    from: c.req.query('from'),
    to: c.req.query('to'),
    page: Number(c.req.query('page') ?? 1),
    limit: Number(c.req.query('limit') ?? 100),
  }));
}

function requireIdempotencyKey(context: Context) {
  const key = context.req.header('Idempotency-Key')?.trim();
  if (!key) throw new Error('Idempotency-Key header is required.');
  return key;
}

export async function handleRecordFareSnapshot(c: Context) {
  requireIdempotencyKey(c);
  return c.json(await fareCalculationService.recordFareSnapshot(
    c.req.valid('json' as never),
  ), 201);
}

export async function handleUpdateFarePaymentStatus(c: Context) {
  requireIdempotencyKey(c);
  const { paymentStatus } = c.req.valid('json' as never) as {
    paymentStatus: string;
  };
  return c.json(await fareCalculationService.updatePaymentStatus(
    c.req.param('rideId')!,
    paymentStatus,
  ));
}

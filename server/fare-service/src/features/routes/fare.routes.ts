import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { EstimateFareSchema, CalculateFinalFareSchema } from '../schemas/fare.schema.ts';
import { FareService } from '../services/fare.service.ts';

export const fareRouter = new Hono();
const fareService = new FareService();

fareRouter.post('/estimate', zValidator('json', EstimateFareSchema), async (c) => {
  const body = c.req.valid('json');
  const result = await fareService.estimateFares(body.distanceKm, body.durationMinutes);
  return c.json({
    success: true,
    data: result,
  });
});

fareRouter.post('/v1/estimate', zValidator('json', EstimateFareSchema), async (c) => {
  const body = c.req.valid('json');
  const result = await fareService.estimateFares(body.distanceKm, body.durationMinutes);
  return c.json({
    success: true,
    data: result,
  });
});

fareRouter.post('/calculate-final', zValidator('json', CalculateFinalFareSchema), async (c) => {
  const body = c.req.valid('json');
  const result = await fareService.calculateFinalFare(
    body.rideId,
    body.distanceKm,
    body.durationMinutes,
    body.rideType,
    body.surgeMultiplier,
  );
  return c.json({
    success: true,
    data: result,
  });
});

fareRouter.post('/v1/calculate-final', zValidator('json', CalculateFinalFareSchema), async (c) => {
  const body = c.req.valid('json');
  const result = await fareService.calculateFinalFare(
    body.rideId,
    body.distanceKm,
    body.durationMinutes,
    body.rideType,
    body.surgeMultiplier,
  );
  return c.json({
    success: true,
    data: result,
  });
});

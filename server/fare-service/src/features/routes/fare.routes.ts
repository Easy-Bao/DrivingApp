import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { EstimateFareSchema, CalculateFinalFareSchema } from '../schemas/fare.schema.ts';
import {
  handleGetPricingConfigs,
  handleGetRatingConfig,
  handleEstimateFares,
  handleCalculateFinalFare,
} from '../controllers/fare.controller.ts';

export const fareRouter = new Hono();

fareRouter.get('/configs', handleGetPricingConfigs);
fareRouter.get('/rating-config', handleGetRatingConfig);
fareRouter.post('/estimate', zValidator('json', EstimateFareSchema), handleEstimateFares);
fareRouter.post('/calculate-final', zValidator('json', CalculateFinalFareSchema), handleCalculateFinalFare);

import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import {
  EstimateFareSchema,
  CalculateFinalFareSchema,
  RecordFareSnapshotSchema,
  UpdatePricingSchema,
  UpdateFarePaymentStatusSchema,
} from '../schemas/fare.schema.ts';
import {
  handleAdminGetPricing,
  handleAdminGetTransactions,
  handleAdminUpdatePricing,
  handleGetPricingConfigs,
  handleGetRatingConfig,
  handleRecordFareSnapshot,
  handleUpdateFarePaymentStatus,
  handleEstimateFares,
  handleCalculateFinalFare,
} from '../controllers/fare.controller.ts';
import { internalAuthMiddleware } from '../../shared/middleware/internal_auth.ts';

export const fareRouter = new Hono();

fareRouter.get('/configs', handleGetPricingConfigs);
fareRouter.get('/rating-config', handleGetRatingConfig);
fareRouter.post('/estimate', zValidator('json', EstimateFareSchema), handleEstimateFares);
fareRouter.post('/calculate-final', zValidator('json', CalculateFinalFareSchema), handleCalculateFinalFare);
fareRouter.use('/admin/*', internalAuthMiddleware);
fareRouter.get('/admin/pricing', handleAdminGetPricing);
fareRouter.put(
  '/admin/pricing/:serviceType',
  zValidator('json', UpdatePricingSchema),
  handleAdminUpdatePricing,
);
fareRouter.get('/admin/transactions', handleAdminGetTransactions);
fareRouter.use('/internal/*', internalAuthMiddleware);
fareRouter.post(
  '/internal/transactions',
  zValidator('json', RecordFareSnapshotSchema),
  handleRecordFareSnapshot,
);
fareRouter.post(
  '/internal/transactions/:rideId/status',
  zValidator('json', UpdateFarePaymentStatusSchema),
  handleUpdateFarePaymentStatus,
);

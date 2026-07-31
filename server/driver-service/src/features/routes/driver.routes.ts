import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import {
  handleGetOnlineDrivers,
  handleUpdateOnlineStatus,
  handleGetDriverProfile,
  handleGetDriverStats,
  handleGetDriverTripHistory,
  handleGetDriverReviews,
  handleAddDriverReview,
} from '../controllers/driver.controller.ts';
import {
  UpdateOnlineStatusSchema,
} from '../schemas/driver.schema.ts';
import { driverOperationsRouter } from './driver_operations.routes.ts';
import { driverAuthMiddleware } from '../../shared/middleware/auth.ts';

export const driversRouter = new Hono();

driversRouter.route('/', driverOperationsRouter);
driversRouter.get('/online', handleGetOnlineDrivers);
driversRouter.post(
  '/:id/online',
  driverAuthMiddleware,
  zValidator('json', UpdateOnlineStatusSchema),
  handleUpdateOnlineStatus,
);
driversRouter.get('/:id', handleGetDriverProfile);
driversRouter.get('/:id/stats', handleGetDriverStats);
driversRouter.get('/:id/trips', handleGetDriverTripHistory);
driversRouter.get('/:id/reviews', handleGetDriverReviews);
driversRouter.post('/:id/reviews', handleAddDriverReview);

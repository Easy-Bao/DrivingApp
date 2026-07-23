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

export const driversRouter = new Hono();

driversRouter.get('/online', handleGetOnlineDrivers);
driversRouter.post('/:id/online', zValidator('json', UpdateOnlineStatusSchema), handleUpdateOnlineStatus);
driversRouter.get('/:id', handleGetDriverProfile);
driversRouter.get('/:id/stats', handleGetDriverStats);
driversRouter.get('/:id/trips', handleGetDriverTripHistory);
driversRouter.get('/:id/reviews', handleGetDriverReviews);
driversRouter.post('/:id/reviews', handleAddDriverReview);

/**
 * Routing definitions mapping driver endpoints to controller actions, with input validation.
 */
import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import {
  handleRegisterDriver,
  handleLoginDriver,
  handleGetOnlineDrivers,
  handleUpdateOnlineStatus,
  handleGetDriverProfile,
  handleGetDriverStats,
  handleGetDriverTripHistory,
  handleGetDriverReviews,
} from '../controllers/driver.controller.ts';
import {
  CreateDriverSchema,
  LoginDriverSchema,
  UpdateOnlineStatusSchema,
} from '../schemas/driver.schema.ts';

export const driversRouter = new Hono();

driversRouter.post('/signup', zValidator('json', CreateDriverSchema), handleRegisterDriver);
driversRouter.post('/login', zValidator('json', LoginDriverSchema), handleLoginDriver);
driversRouter.get('/online', handleGetOnlineDrivers);
driversRouter.post('/:id/online', zValidator('json', UpdateOnlineStatusSchema), handleUpdateOnlineStatus);
driversRouter.get('/:id', handleGetDriverProfile);
driversRouter.get('/:id/stats', handleGetDriverStats);
driversRouter.get('/:id/trips', handleGetDriverTripHistory);
driversRouter.get('/:id/reviews', handleGetDriverReviews);

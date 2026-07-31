import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { authMiddleware } from '../../middleware/auth.ts';
import {
  handleGetPassengerProfile,
  handleUpdatePassengerProfile,
  handleCreateRideRequest,
  handleGetPassengerRideHistory,
  handleGetPassengerNotifications,
  handleGetPassengersBatch,
  handleGetPassengerRideAccess,
  handleLiftPassengerRestriction,
  handleListPassengerRestrictions,
  handleRestrictPassenger,
} from '../controllers/passenger.controller.ts';
import {
  CreateRideSchema,
  RestrictPassengerSchema,
  LiftPassengerRestrictionSchema,
  UpdatePassengerSchema,
} from '../schemas/passenger.schema.ts';
import { internalAuthMiddleware } from '../../middleware/internal_auth.ts';

export const passengerRouter = new Hono();

passengerRouter.post('/passengers/batch', handleGetPassengersBatch);
passengerRouter.get(
  '/passengers/internal/:id/ride-access',
  internalAuthMiddleware,
  handleGetPassengerRideAccess,
);
passengerRouter.post(
  '/passengers/admin/:id/restrictions',
  internalAuthMiddleware,
  zValidator('json', RestrictPassengerSchema),
  handleRestrictPassenger,
);
passengerRouter.get(
  '/passengers/admin/:id/restrictions',
  internalAuthMiddleware,
  handleListPassengerRestrictions,
);
passengerRouter.post(
  '/passengers/admin/restrictions/:restrictionId/lift',
  internalAuthMiddleware,
  zValidator('json', LiftPassengerRestrictionSchema),
  handleLiftPassengerRestriction,
);
passengerRouter.get('/passengers/:id', handleGetPassengerProfile);
passengerRouter.put('/passengers/:id', authMiddleware, zValidator('json', UpdatePassengerSchema), handleUpdatePassengerProfile);
passengerRouter.post('/rides', authMiddleware, zValidator('json', CreateRideSchema), handleCreateRideRequest);
passengerRouter.get('/passengers/:id/rides', authMiddleware, handleGetPassengerRideHistory);
passengerRouter.get('/passengers/:id/notifications', authMiddleware, handleGetPassengerNotifications);

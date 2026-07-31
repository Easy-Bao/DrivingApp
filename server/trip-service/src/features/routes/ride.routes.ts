import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import {
  handleCreateRide,
  handleGetActiveRides,
  handleGetRideDetails,
  handleGetRidesByDriver,
  handleGetRidesByPassenger,
  handleAcceptRide,
  handleUpdateRideStatus,
  handleGetRideReport,
  handleReconcileRideStatuses,
} from '../controllers/ride.controller.ts';
import {
  CreateRideSchema,
  AcceptRideSchema,
  InternalCreateRideSchema,
  UpdateStatusSchema,
} from '../schemas/ride.schema.ts';
import {
  authMiddleware,
  internalAuthMiddleware,
} from '../../shared/middleware/auth.ts';

export const ridesRouter = new Hono();

ridesRouter.post('/', authMiddleware, zValidator('json', CreateRideSchema), handleCreateRide);
ridesRouter.get('/active', handleGetActiveRides);
ridesRouter.get('/admin/report', internalAuthMiddleware, handleGetRideReport);
ridesRouter.post('/internal/reconcile', internalAuthMiddleware, handleReconcileRideStatuses);
ridesRouter.post(
  '/internal',
  internalAuthMiddleware,
  zValidator('json', InternalCreateRideSchema),
  handleCreateRide,
);
ridesRouter.post(
  '/internal/:id/accept',
  internalAuthMiddleware,
  zValidator('json', AcceptRideSchema),
  handleAcceptRide,
);
ridesRouter.post(
  '/internal/:id/status',
  internalAuthMiddleware,
  zValidator('json', UpdateStatusSchema),
  handleUpdateRideStatus,
);
ridesRouter.get('/:id', handleGetRideDetails);
ridesRouter.get('/driver/:driverId', handleGetRidesByDriver);
ridesRouter.get('/passenger/:passengerId', handleGetRidesByPassenger);
ridesRouter.post(
  '/:id/accept',
  internalAuthMiddleware,
  zValidator('json', AcceptRideSchema),
  handleAcceptRide,
);
ridesRouter.post(
  '/:id/status',
  authMiddleware,
  zValidator('json', UpdateStatusSchema),
  handleUpdateRideStatus,
);

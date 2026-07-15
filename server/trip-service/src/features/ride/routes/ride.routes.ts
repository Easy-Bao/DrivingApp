/**
 * Routing definitions mapping ride endpoints to controller actions, with input validation.
 */
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
} from '../controllers/ride.controller.ts';
import {
  CreateRideSchema,
  AcceptRideSchema,
  UpdateStatusSchema,
} from '../schemas/ride.schema.ts';

export const ridesRouter = new Hono();

ridesRouter.post('/', zValidator('json', CreateRideSchema), handleCreateRide);
ridesRouter.get('/active', handleGetActiveRides);
ridesRouter.get('/:id', handleGetRideDetails);
ridesRouter.get('/driver/:driverId', handleGetRidesByDriver);
ridesRouter.get('/passenger/:passengerId', handleGetRidesByPassenger);
ridesRouter.post('/:id/accept', zValidator('json', AcceptRideSchema), handleAcceptRide);
ridesRouter.post('/:id/status', zValidator('json', UpdateStatusSchema), handleUpdateRideStatus);

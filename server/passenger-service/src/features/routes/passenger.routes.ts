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
} from '../controllers/passenger.controller.ts';
import {
  CreateRideSchema,
  UpdatePassengerSchema,
} from '../schemas/passenger.schema.ts';

export const passengerRouter = new Hono();

passengerRouter.post('/passengers/batch', handleGetPassengersBatch);
passengerRouter.get('/passengers/:id', handleGetPassengerProfile);
passengerRouter.put('/passengers/:id', authMiddleware, zValidator('json', UpdatePassengerSchema), handleUpdatePassengerProfile);
passengerRouter.post('/rides', authMiddleware, zValidator('json', CreateRideSchema), handleCreateRideRequest);
passengerRouter.get('/passengers/:id/rides', authMiddleware, handleGetPassengerRideHistory);
passengerRouter.get('/passengers/:id/notifications', authMiddleware, handleGetPassengerNotifications);

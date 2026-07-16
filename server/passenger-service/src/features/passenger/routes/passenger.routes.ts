import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { authMiddleware } from '../../../middleware/auth.ts';
import {
  handleRegisterPassenger,
  handleVerifyOtp,
  handleForgotPassword,
  handleLoginPassenger,
  handleGetPassengerProfile,
  handleUpdatePassengerProfile,
  handleCreateRideRequest,
  handleGetPassengerRideHistory,
  handleGetPassengerNotifications,
  handleGetPassengersBatch,
} from '../controllers/passenger.controller.ts';
import {
  CreatePassengerSchema,
  LoginSchema,
  CreateRideSchema,
  UpdatePassengerSchema,
} from '../schemas/passenger.schema.ts';

export const passengerRouter = new Hono();

passengerRouter.post('/passengers', zValidator('json', CreatePassengerSchema), handleRegisterPassenger);
passengerRouter.post('/passengers/verify-otp', handleVerifyOtp);
passengerRouter.post('/passengers/forgot-password', handleForgotPassword);
passengerRouter.post('/passengers/login', zValidator('json', LoginSchema), handleLoginPassenger);
passengerRouter.post('/passengers/batch', handleGetPassengersBatch);
passengerRouter.get('/passengers/:id', handleGetPassengerProfile);
passengerRouter.put('/passengers/:id', authMiddleware, zValidator('json', UpdatePassengerSchema), handleUpdatePassengerProfile);
passengerRouter.post('/rides', authMiddleware, zValidator('json', CreateRideSchema), handleCreateRideRequest);
passengerRouter.get('/passengers/:id/rides', authMiddleware, handleGetPassengerRideHistory);
passengerRouter.get('/passengers/:id/notifications', authMiddleware, handleGetPassengerNotifications);

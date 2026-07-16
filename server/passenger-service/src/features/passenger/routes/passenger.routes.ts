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
  handleRegisterEmail,
  handleVerifyEmailOtp,
  handleCompleteProfile,
} from '../controllers/passenger.controller.ts';
import {
  CreatePassengerSchema,
  LoginSchema,
  CreateRideSchema,
  UpdatePassengerSchema,
  RegisterEmailSchema,
  VerifyEmailOtpSchema,
  CompleteProfileSchema,
} from '../schemas/passenger.schema.ts';

export const passengerRouter = new Hono();

passengerRouter.post('/passengers', zValidator('json', CreatePassengerSchema), handleRegisterPassenger);
passengerRouter.post('/passengers/register-email', zValidator('json', RegisterEmailSchema), handleRegisterEmail);
passengerRouter.post('/passengers/verify-otp', handleVerifyOtp);
passengerRouter.post('/passengers/verify-email-otp', zValidator('json', VerifyEmailOtpSchema), handleVerifyEmailOtp);
passengerRouter.put('/passengers/complete-profile', authMiddleware, zValidator('json', CompleteProfileSchema), handleCompleteProfile);
passengerRouter.post('/passengers/forgot-password', handleForgotPassword);
passengerRouter.post('/passengers/login', zValidator('json', LoginSchema), handleLoginPassenger);
passengerRouter.post('/passengers/batch', handleGetPassengersBatch);
passengerRouter.get('/passengers/:id', handleGetPassengerProfile);
passengerRouter.put('/passengers/:id', authMiddleware, zValidator('json', UpdatePassengerSchema), handleUpdatePassengerProfile);
passengerRouter.post('/rides', authMiddleware, zValidator('json', CreateRideSchema), handleCreateRideRequest);
passengerRouter.get('/passengers/:id/rides', authMiddleware, handleGetPassengerRideHistory);
passengerRouter.get('/passengers/:id/notifications', authMiddleware, handleGetPassengerNotifications);

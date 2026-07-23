import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import {
  RegisterPassengerSchema,
  LoginPassengerSchema,
} from '../../schemas/passenger/passenger.zod.ts';
import {
  handleRegisterPassengerAccount,
  handleAuthenticatePassenger,
} from '../../controllers/passenger/passenger.controller.ts';

export const passengerAuthRouter = new Hono();

passengerAuthRouter.post('/register', zValidator('json', RegisterPassengerSchema), handleRegisterPassengerAccount);
passengerAuthRouter.post('/login', zValidator('json', LoginPassengerSchema), handleAuthenticatePassenger);

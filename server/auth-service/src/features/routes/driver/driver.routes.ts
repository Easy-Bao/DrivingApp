import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import {
  RegisterDriverSchema,
  LoginDriverSchema,
} from '../../schemas/driver/driver.zod.ts';
import {
  handleRegisterDriverAccount,
  handleAuthenticateDriver,
} from '../../controllers/driver/driver.controller.ts';

export const driverAuthRouter = new Hono();

driverAuthRouter.post('/register', zValidator('json', RegisterDriverSchema), handleRegisterDriverAccount);
driverAuthRouter.post('/login', zValidator('json', LoginDriverSchema), handleAuthenticateDriver);

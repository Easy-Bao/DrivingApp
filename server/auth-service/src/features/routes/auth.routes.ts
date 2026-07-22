import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import {
  RegisterAuthSchema,
  LoginAuthSchema,
  VerifyOtpAuthSchema,
  VerifyTokenAuthSchema,
} from '../schemas/auth.zod.ts';
import {
  handleRegisterPassenger,
  handleLoginPassenger,
  handleRegisterDriver,
  handleLoginDriver,
  handleVerifyOtp,
  handleVerifyToken,
} from '../controllers/auth.controller.ts';

export const authRouter = new Hono();

authRouter.post('/passenger/register', zValidator('json', RegisterAuthSchema.omit({ role: true })), handleRegisterPassenger);
authRouter.post('/passenger/login', zValidator('json', LoginAuthSchema.omit({ role: true })), handleLoginPassenger);

authRouter.post('/driver/register', zValidator('json', RegisterAuthSchema.omit({ role: true })), handleRegisterDriver);
authRouter.post('/driver/login', zValidator('json', LoginAuthSchema.omit({ role: true })), handleLoginDriver);

authRouter.post('/verify-otp', zValidator('json', VerifyOtpAuthSchema), handleVerifyOtp);
authRouter.post('/verify-token', zValidator('json', VerifyTokenAuthSchema), handleVerifyToken);

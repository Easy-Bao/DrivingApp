import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import {
  VerifyOtpSchema,
  ForgotPasswordSchema,
  VerifyTokenSchema,
} from '../../schemas/common/common.zod.ts';
import {
  handleVerifyOneTimePassword,
  handleSendForgotPasswordOneTimePassword,
  handleVerifyAuthenticationToken,
} from '../../controllers/common/common.controller.ts';

export const commonAuthRouter = new Hono();

commonAuthRouter.post('/verify-otp', zValidator('json', VerifyOtpSchema), handleVerifyOneTimePassword);
commonAuthRouter.post('/forgot-password', zValidator('json', ForgotPasswordSchema), handleSendForgotPasswordOneTimePassword);
commonAuthRouter.post('/verify-token', zValidator('json', VerifyTokenSchema), handleVerifyAuthenticationToken);

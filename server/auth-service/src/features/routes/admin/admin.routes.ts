import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import {
  handleAuthenticateAdmin,
  handleVerifyAdminSession,
} from '../../controllers/admin/admin.controller.ts';
import { LoginAdminSchema } from '../../schemas/admin/admin.zod.ts';
import { VerifyTokenSchema } from '../../schemas/common/common.zod.ts';

export const adminAuthRouter = new Hono();

adminAuthRouter.post('/login', zValidator('json', LoginAdminSchema), handleAuthenticateAdmin);
adminAuthRouter.post('/verify', zValidator('json', VerifyTokenSchema), handleVerifyAdminSession);

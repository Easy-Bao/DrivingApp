import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { handleAuthenticateAdmin } from '../../controllers/admin/admin.controller.ts';
import { LoginAdminSchema } from '../../schemas/admin/admin.zod.ts';

export const adminAuthRouter = new Hono();

adminAuthRouter.post('/login', zValidator('json', LoginAdminSchema), handleAuthenticateAdmin);

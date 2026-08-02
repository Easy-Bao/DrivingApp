import { zValidator } from '@hono/zod-validator';
import { Hono } from 'hono';
import {
  AdminVariables,
  adminAuthMiddleware,
} from '../../common/middleware/auth.ts';
import { AdminLoginSchema } from './auth.schema.ts';
import { AuthService } from './auth.service.ts';

const authService = new AuthService();

export const authRoutes = new Hono<{ Variables: AdminVariables }>();

authRoutes.post('/login', zValidator('json', AdminLoginSchema), async (context) => {
  const body = context.req.valid('json');
  return context.json(await authService.login(body.email, body.password));
});

authRoutes.get('/session', adminAuthMiddleware, (context) => context.json({
  adminId: context.get('adminId'),
  email: context.get('adminEmail'),
  role: 'admin',
}));

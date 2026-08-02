import { Context } from 'hono';
import { AdminVariables } from '../../shared/middleware/auth.ts';
import { AuthRepository } from '../repositories/auth.repository.ts';
import { AuthService } from '../services/auth.service.ts';

const authService = new AuthService(new AuthRepository());

export async function handleAdminLogin(context: Context) {
  const body = context.req.valid('json' as never) as {
    email: string;
    password: string;
  };
  return context.json(await authService.login(body.email, body.password));
}

export function handleAdminSession(
  context: Context<{ Variables: AdminVariables }>,
) {
  return context.json({
    adminId: context.get('adminId'),
    email: context.get('adminEmail'),
    role: 'admin',
  });
}

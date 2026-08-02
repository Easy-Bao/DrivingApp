import { Context, Next } from 'hono';
import { verify } from 'hono/jwt';
import { loadAdminConfiguration } from '../../config/env.ts';

export type AdminVariables = {
  adminId: string;
  adminEmail: string;
};

/** Accepts only tokens issued by the isolated Admin service for the owner role. */
export async function adminAuthMiddleware(
  context: Context<{ Variables: AdminVariables }>,
  next: Next,
) {
  const authorization = context.req.header('Authorization');
  if (!authorization?.startsWith('Bearer ')) {
    return context.json({ code: 'UNAUTHORIZED', message: 'Authentication is required.' }, 401);
  }

  try {
    const { ADMIN_JWT_SECRET } = loadAdminConfiguration();
    const payload = await verify(authorization.slice(7), ADMIN_JWT_SECRET, 'HS256');
    if (
      payload.role !== 'admin'
      || typeof payload.sub !== 'string'
      || typeof payload.email !== 'string'
    ) {
      return context.json({ code: 'FORBIDDEN', message: 'Admin access is required.' }, 403);
    }
    context.set('adminId', payload.sub);
    context.set('adminEmail', payload.email);
    await next();
  } catch {
    return context.json({
      code: 'UNAUTHORIZED',
      message: 'Authentication is invalid or expired.',
    }, 401);
  }
}

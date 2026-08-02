import { Context, Next } from 'hono';
import { verify } from 'hono/jwt';
import { loadAdminConfiguration } from '../../config.ts';

export type AdminVariables = {
  adminId: string;
  adminEmail: string;
};

/**
 * Verifies tokens signed only by the isolated Admin service. Passenger and
 * Driver credentials cannot cross this boundary because they use a different
 * signing secret and must never carry the Admin role.
 */
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
    return context.json({ code: 'UNAUTHORIZED', message: 'Authentication is invalid or expired.' }, 401);
  }
}

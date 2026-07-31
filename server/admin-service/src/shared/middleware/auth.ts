import { Context, Next } from 'hono';
import { verify } from 'hono/jwt';

export type AdminVariables = {
  adminId: string;
  adminEmail: string;
};

export async function adminAuthMiddleware(
  context: Context<{ Variables: AdminVariables }>,
  next: Next,
) {
  const authorization = context.req.header('Authorization');
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error('Security Configuration Error: JWT_SECRET is required.');
  }
  if (!authorization?.startsWith('Bearer ')) {
    return context.json({ code: 'UNAUTHORIZED', message: 'Authentication is required.' }, 401);
  }

  try {
    const payload = await verify(authorization.slice(7), secret, 'HS256');
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

export async function internalAuthMiddleware(context: Context, next: Next) {
  const expectedToken = process.env.INTERNAL_SERVICE_TOKEN;
  if (!expectedToken) {
    throw new Error('Security Configuration Error: INTERNAL_SERVICE_TOKEN is required.');
  }
  if (context.req.header('X-Internal-Service-Token') !== expectedToken) {
    return context.json({ code: 'FORBIDDEN', message: 'Internal service access is required.' }, 403);
  }
  await next();
}

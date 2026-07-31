import { Context, Next } from 'hono';
import { verify } from 'hono/jwt';

export type AuthVariables = {
  userId: string;
  role: string;
};

export async function authMiddleware(
  context: Context<{ Variables: AuthVariables }>,
  next: Next,
) {
  const authorization = context.req.header('Authorization');
  const secret = process.env.JWT_SECRET;
  if (!secret) throw new Error('Security Configuration Error: JWT_SECRET is required.');
  if (!authorization?.startsWith('Bearer ')) {
    return context.json({ code: 'UNAUTHORIZED', message: 'Authentication is required.' }, 401);
  }
  try {
    const payload = await verify(authorization.slice(7), secret, 'HS256');
    if (typeof payload.sub !== 'string' || typeof payload.role !== 'string') {
      return context.json({ code: 'UNAUTHORIZED', message: 'Authentication is invalid.' }, 401);
    }
    context.set('userId', payload.sub);
    context.set('role', payload.role);
    await next();
  } catch {
    return context.json({ code: 'UNAUTHORIZED', message: 'Authentication is invalid or expired.' }, 401);
  }
}

export async function internalAuthMiddleware(context: Context, next: Next) {
  const token = process.env.INTERNAL_SERVICE_TOKEN;
  if (!token) {
    throw new Error('Security Configuration Error: INTERNAL_SERVICE_TOKEN is required.');
  }
  if (context.req.header('X-Internal-Service-Token') !== token) {
    return context.json({ code: 'FORBIDDEN', message: 'Internal service access is required.' }, 403);
  }
  await next();
}

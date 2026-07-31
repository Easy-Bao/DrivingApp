import { timingSafeEqual } from 'node:crypto';
import { Context, Next } from 'hono';
import { verify } from 'hono/jwt';

export type AuthVariables = {
  userId: string;
  role: string;
};

function matchesInternalToken(context: Context): boolean {
  const configuredToken = process.env.INTERNAL_SERVICE_TOKEN;
  if (!configuredToken?.trim()) return false;
  const providedToken = context.req.header('X-Internal-Service-Token') ?? '';
  const expected = Buffer.from(configuredToken);
  const provided = Buffer.from(providedToken);
  return expected.length === provided.length && timingSafeEqual(expected, provided);
}

export async function authMiddleware(
  context: Context<{ Variables: AuthVariables }>,
  next: Next,
) {
  const authorization = context.req.header('Authorization');
  const secret = process.env.JWT_SECRET;
  if (!secret?.trim()) {
    throw new Error('Security Configuration Error: JWT_SECRET is required.');
  }
  if (!authorization?.startsWith('Bearer ')) {
    return context.json({ code: 'UNAUTHORIZED', message: 'Authentication is required.' }, 401);
  }

  let payload;
  try {
    payload = await verify(authorization.slice(7), secret, 'HS256');
  } catch {
    return context.json({
      code: 'UNAUTHORIZED',
      message: 'Authentication is invalid or expired.',
    }, 401);
  }
  if (typeof payload.sub !== 'string' || typeof payload.role !== 'string') {
    return context.json({ code: 'UNAUTHORIZED', message: 'Authentication is invalid.' }, 401);
  }
  context.set('userId', payload.sub);
  context.set('role', payload.role);
  await next();
}

export function requireRole(requiredRole: 'passenger' | 'driver') {
  return async (
    context: Context<{ Variables: AuthVariables }>,
    next: Next,
  ) => {
    if (context.get('role') !== requiredRole) {
      return context.json({
        code: 'FORBIDDEN',
        message: `A ${requiredRole} account is required.`,
      }, 403);
    }
    await next();
  };
}

export async function authOrInternalMiddleware(
  context: Context<{ Variables: AuthVariables }>,
  next: Next,
) {
  if (matchesInternalToken(context)) {
    context.set('userId', 'internal-service');
    context.set('role', 'internal');
    await next();
    return;
  }
  await authMiddleware(context, next);
}

export function requireAnyRole(...roles: string[]) {
  return async (
    context: Context<{ Variables: AuthVariables }>,
    next: Next,
  ) => {
    if (!roles.includes(context.get('role'))) {
      return context.json({ code: 'FORBIDDEN', message: 'Access is forbidden.' }, 403);
    }
    await next();
  };
}

export async function internalAuthMiddleware(context: Context, next: Next) {
  const configuredToken = process.env.INTERNAL_SERVICE_TOKEN;
  if (!configuredToken?.trim()) {
    throw new Error('Security Configuration Error: INTERNAL_SERVICE_TOKEN is required.');
  }

  if (!matchesInternalToken(context)) {
    return context.json({
      code: 'FORBIDDEN',
      message: 'Internal service access is required.',
    }, 403);
  }
  await next();
}

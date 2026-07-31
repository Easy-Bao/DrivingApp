import { timingSafeEqual } from 'node:crypto';
import { Context, Next } from 'hono';
import { verify } from 'hono/jwt';

export type DriverAuthEnvironment = {
  Variables: {
    driverId: string;
  };
};

function unauthorized(context: Context, code = 'UNAUTHORIZED', message = 'Unauthorized') {
  return context.json({ code, message }, 401);
}

export async function driverAuthMiddleware(
  context: Context<DriverAuthEnvironment>,
  next: Next,
) {
  const authorizationHeader = context.req.header('Authorization');
  if (!authorizationHeader?.startsWith('Bearer ')) {
    return unauthorized(context);
  }

  const secret = process.env.JWT_SECRET;
  if (!secret?.trim()) {
    throw new Error('Security Configuration Error: JWT_SECRET is required but not set.');
  }

  try {
    const payload = await verify(authorizationHeader.substring(7), secret, 'HS256');
    if (typeof payload.sub !== 'string' || payload.role !== 'driver') {
      return unauthorized(context, 'DRIVER_TOKEN_REQUIRED', 'A driver token is required');
    }
    context.set('driverId', payload.sub);
    await next();
  } catch (_) {
    return unauthorized(context);
  }
}

export async function internalServiceMiddleware(context: Context, next: Next) {
  const configuredToken = process.env.INTERNAL_SERVICE_TOKEN;
  if (!configuredToken?.trim()) {
    throw new Error(
      'Security Configuration Error: INTERNAL_SERVICE_TOKEN is required but not set.',
    );
  }

  const providedToken = context.req.header('x-internal-service-token') || '';
  const configuredBytes = Buffer.from(configuredToken);
  const providedBytes = Buffer.from(providedToken);
  if (
    configuredBytes.length !== providedBytes.length
    || !timingSafeEqual(configuredBytes, providedBytes)
  ) {
    return unauthorized(context, 'INTERNAL_TOKEN_REQUIRED', 'A valid internal token is required');
  }

  await next();
}

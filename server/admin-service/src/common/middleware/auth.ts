import { Context, Next } from 'hono';
import { verify } from 'hono/jwt';
import { loadAdminConfiguration } from '../../config/env.ts';

export type AdminVariables = {
  adminId: string;
  adminEmail: string;
};

/**
 * Admin request boundary: prevents Passenger, Driver, and shared-service tokens
 * from entering owner operations even when a caller reaches the Admin route
 * through the API gateway.
 *
 * The middleware first extracts the bearer token, verifies its HS256 signature
 * with the dedicated Admin secret, and then requires an Admin role plus string
 * subject and email claims. Only after every check succeeds are `adminId` and
 * `adminEmail` copied into the Hono request context for downstream routes.
 *
 * Verification is stateless, so concurrent requests do not share counters or
 * mutable session data; token expiry is enforced by Hono before the request can
 * continue. The SvelteKit server supplies the bearer token from its HttpOnly
 * cookie, while browser JavaScript never receives either the token or secret.
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
    return context.json({
      code: 'UNAUTHORIZED',
      message: 'Authentication is invalid or expired.',
    }, 401);
  }
}

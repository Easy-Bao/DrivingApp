/**
 * Authentication middleware: extracts JWT token from Authorization header, validates it, and attaches the passenger ID to request context.
 */
import { Context, Next } from 'hono';
import { verify } from 'hono/jwt';

export async function authMiddleware(c: Context, next: Next) {
  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json({ error: 'Unauthorized' }, 401);
  }

  const token = authHeader.substring(7);
  const secret = process.env.JWT_SECRET || 'secret';

  try {
    const payload = await verify(token, secret);
    if (!payload || typeof payload.sub !== 'string') {
      return c.json({ error: 'Unauthorized' }, 401);
    }

    c.set('passengerId', payload.sub);
    await next();
  } catch (error) {
    return c.json({ error: 'Unauthorized' }, 401);
  }
}

import { Context, Next } from 'hono';

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

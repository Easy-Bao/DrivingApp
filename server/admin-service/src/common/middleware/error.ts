import { Context } from 'hono';
import { HTTPException } from 'hono/http-exception';

export function globalErrorHandler(error: Error, context: Context) {
  if (error instanceof HTTPException) {
    const code = /^[A-Z][A-Z0-9_]+$/.test(error.message)
      ? error.message
      : error.status === 404
        ? 'NOT_FOUND'
        : 'REQUEST_FAILED';
    return context.json({ code, message: error.message }, error.status);
  }
  console.error('[admin-service]', error);
  return context.json({
    code: 'INTERNAL_ERROR',
    message: 'The request could not be completed.',
  }, 500);
}

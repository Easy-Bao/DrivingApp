import type { Context } from 'hono';
import { Logger } from '../logger/logger.ts';

export function globalErrorHandler(err: Error, c: Context) {
  Logger.error('Unhandled Server Exception:', err);

  if ('status' in err && typeof (err as any).status === 'number') {
    return c.json(
      {
        success: false,
        error: {
          name: err.name || 'HttpException',
          message: err.message,
        },
      },
      (err as any).status,
    );
  }

  return c.json(
    {
      success: false,
      error: {
        name: 'InternalServerError',
        message: err.message || 'An unexpected error occurred.',
      },
    },
    500,
  );
}

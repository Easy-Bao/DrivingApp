import type { Context } from 'hono';
import { Logger } from '../logger/logger.ts';

interface HttpStatusError extends Error {
  status?: number;
}

export function globalErrorHandler(err: Error, c: Context) {
  Logger.error('Unhandled Server Exception:', err);
  const statusError = err as HttpStatusError;

  if (typeof statusError.status === 'number') {
    const statusCode = statusError.status >= 100 && statusError.status < 600 ? statusError.status : 500;
    return c.json(
      {
        success: false,
        error: {
          name: err.name || 'HttpException',
          message: err.message,
        },
      },
      statusCode as 500
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
    500
  );
}

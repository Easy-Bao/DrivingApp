import type { Context } from 'hono';
import { Logger } from '../logger/logger.ts';

interface HttpStatusError extends Error {
  status?: number;
}

export function globalErrorHandler(err: Error, c: Context) {
  Logger.error('Unhandled Server Exception:', err);
  const statusError = err as HttpStatusError;
  const knownCodes = new Set([
    'FARE_SNAPSHOT_NOT_FOUND',
    'IDEMPOTENCY_KEY_REUSED',
    'INVALID_COMMISSION_SNAPSHOT',
  ]);
  const code = knownCodes.has(err.message) ? err.message : 'INTERNAL_ERROR';
  const knownStatus = err.message === 'FARE_SNAPSHOT_NOT_FOUND'
    ? 404
    : err.message === 'IDEMPOTENCY_KEY_REUSED'
      ? 409
      : err.message === 'INVALID_COMMISSION_SNAPSHOT'
        ? 422
        : undefined;

  if (typeof statusError.status === 'number' || knownStatus) {
    const statusCode = knownStatus
      ?? (statusError.status! >= 100 && statusError.status! < 600
        ? statusError.status!
        : 500);
    return c.json(
      {
        success: false,
        code,
        message: err.message,
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
      code,
      message: err.message || 'An unexpected error occurred.',
      error: {
        name: 'InternalServerError',
        message: err.message || 'An unexpected error occurred.',
      },
    },
    500
  );
}

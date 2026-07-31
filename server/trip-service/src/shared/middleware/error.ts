import { ErrorHandler } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { Logger } from '../logger/logger.ts';

export const globalErrorHandler: ErrorHandler = (error, context) => {
  if (error instanceof HTTPException) {
    Logger.warn(`HTTP Exception status ${error.status}: ${error.message}`);
    const knownCodes = new Set([
      'ACCOUNT_RESTRICTED',
      'DRIVER_NOT_APPROVED',
      'FORBIDDEN',
      'INSUFFICIENT_CREDIT',
      'IDEMPOTENCY_KEY_REUSED',
      'OUTSIDE_SERVICE_ZONE',
      'PASSENGER_ID_REQUIRED',
      'SERVICE_ZONE_NOT_CONFIGURED',
    ]);
    const code = knownCodes.has(error.message)
      ? error.message
      : error.status === 404
        ? 'NOT_FOUND'
        : 'REQUEST_FAILED';
    return context.json({ code, message: error.message, error: error.message }, error.status);
  }

  Logger.error('Unhandled runtime exception caught in middleware:', error);
  return context.json({ error: 'Internal Server Error' }, 500);
};

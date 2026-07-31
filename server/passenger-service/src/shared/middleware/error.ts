import { ErrorHandler } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { Logger } from '../logger/logger.ts';

export const globalErrorHandler: ErrorHandler = (error, context) => {
  if (error instanceof HTTPException) {
    Logger.warn(`HTTP Exception status ${error.status}: ${error.message}`);
    const hasStableCode = [
      'ACCOUNT_RESTRICTED',
      'IDEMPOTENCY_KEY_REUSED',
      'INVALID_ADMIN_ACTOR',
      'INVALID_IDEMPOTENCY_KEY',
      'RESTRICTION_ALREADY_LIFTED',
    ].includes(error.message);
    return context.json(
      hasStableCode
        ? {
            code: error.message,
            message: error.message,
            error: error.message,
          }
        : { error: error.message },
      error.status,
    );
  }

  Logger.error('Unhandled runtime exception caught in middleware:', error);
  return context.json({ error: 'Internal Server Error' }, 500);
};

/**
 * Global exception interceptor catching HTTPException and uncaught runtime errors.
 */
import { ErrorHandler } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { Logger } from '../logger/logger.ts';

export const globalErrorHandler: ErrorHandler = (error, context) => {
  if (error instanceof HTTPException) {
    Logger.warn(`HTTP Exception status ${error.status}: ${error.message}`);
    return context.json({ error: error.message }, error.status);
  }

  Logger.error('Unhandled runtime exception caught in middleware:', error);
  return context.json({ error: 'Internal Server Error' }, 500);
};

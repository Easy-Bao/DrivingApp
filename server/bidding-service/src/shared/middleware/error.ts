import { ErrorHandler } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { Logger } from '../logger/logger.ts';

export const globalErrorHandler: ErrorHandler = (error, context) => {
  if (error instanceof HTTPException) {
    Logger.warn(`HTTP Exception status ${error.status}: ${error.message}`);
    return context.json({
      code: error.message,
      message: error.message,
      error: error.message,
    }, error.status);
  }

  Logger.error('Unhandled runtime exception caught in middleware:', error);
  return context.json({
    code: 'INTERNAL_SERVER_ERROR',
    message: 'Internal Server Error',
    error: 'Internal Server Error',
  }, 500);
};

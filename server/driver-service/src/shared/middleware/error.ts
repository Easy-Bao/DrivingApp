import { ErrorHandler } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { Logger } from '../logger/logger.ts';
import { DriverDomainError } from '../../features/entities/driver_operations.types.ts';

export const globalErrorHandler: ErrorHandler = (error, context) => {
  if (error instanceof DriverDomainError) {
    Logger.warn(`Driver domain error ${error.code}: ${error.message}`);
    return context.json({
      code: error.code,
      message: error.message,
      error: error.message,
    }, error.status);
  }

  if (error instanceof HTTPException) {
    Logger.warn(`HTTP Exception status ${error.status}: ${error.message}`);
    return context.json({ error: error.message }, error.status);
  }

  Logger.error('Unhandled runtime exception caught in middleware:', error);
  return context.json({ error: 'Internal Server Error' }, 500);
};

/**
 * Routing definitions mapping telemetry endpoints to controller actions, with input validation.
 */
import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { handleUpdateLocation, handleGetLocation } from '../controllers/telemetry.controller.ts';
import { LocationUpdateSchema } from '../schemas/telemetry.schema.ts';

export const telemetryRouter = new Hono();

telemetryRouter.post('/location', zValidator('json', LocationUpdateSchema), handleUpdateLocation);
telemetryRouter.get('/location/:driverId', handleGetLocation);

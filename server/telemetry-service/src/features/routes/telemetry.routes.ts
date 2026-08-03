import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { handleGetLocation, handleGetPassengerLocation, handleUpdateLocation, handleUpdatePassengerLocation } from '../controllers/telemetry.controller.ts';
import { LocationUpdateSchema, PassengerLocationUpdateSchema } from '../schemas/telemetry.schema.ts';

export const telemetryRouter = new Hono();

telemetryRouter.post('/location', zValidator('json', LocationUpdateSchema), handleUpdateLocation);
telemetryRouter.get('/location/:driverId', handleGetLocation);
telemetryRouter.post('/passenger/:rideId', zValidator('json', PassengerLocationUpdateSchema), handleUpdatePassengerLocation);
telemetryRouter.get('/passenger/:rideId', handleGetPassengerLocation);

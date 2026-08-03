import { Context } from 'hono';
import { InMemoryTelemetryRepository } from '../repositories/telemetry.repository.ts';
import { TelemetryService } from '../services/telemetry.service.ts';

const telemetryRepository = new InMemoryTelemetryRepository();
const telemetryService = new TelemetryService(telemetryRepository);

export async function handleUpdateLocation(context: Context) {
  const { driverId, lat, lng } = await context.req.json();
  telemetryService.updateLocation(driverId, lat, lng);
  return context.json({ success: true }, 200);
}

export async function handleGetLocation(context: Context) {
  const driverId = context.req.param('driverId');
  if (!driverId) {
    return context.json({ error: 'driverId is required' }, 400);
  }
  const loc = telemetryService.getLocation(driverId);
  return context.json(loc, 200);
}

export async function handleUpdatePassengerLocation(context: Context) {
  const rideId = context.req.param('rideId');
  if (!rideId) {
    return context.json({ error: 'rideId is required' }, 400);
  }
  const { lat, lng } = await context.req.json();
  telemetryService.updatePassengerLocation(rideId, lat, lng);
  return context.json({ success: true }, 200);
}

export async function handleGetPassengerLocation(context: Context) {
  const rideId = context.req.param('rideId');
  if (!rideId) {
    return context.json({ error: 'rideId is required' }, 400);
  }
  const loc = telemetryService.getPassengerLocation(rideId);
  return context.json(loc, 200);
}

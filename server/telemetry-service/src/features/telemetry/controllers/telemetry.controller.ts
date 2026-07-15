/**
 * Controller layer processing HTTP context for telemetry endpoints, mapping outputs from TelemetryService.
 */
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
  const loc = telemetryService.getLocation(driverId);
  return context.json(loc, 200);
}

/**
 * Controller layer processing HTTP context for driver endpoints, mapping outputs from DriverService.
 */
import { Context } from 'hono';
import { DrizzleDriverRepository } from '../repositories/driver.repository.ts';
import { DriverService } from '../services/driver.service.ts';

const driverRepository = new DrizzleDriverRepository();
const driverService = new DriverService(driverRepository);

export async function handleRegisterDriver(context: Context) {
  const body = await context.req.json();
  const driver = await driverService.registerDriver(body);
  return context.json(driver, 201);
}

export async function handleLoginDriver(context: Context) {
  const body = await context.req.json();
  const driver = await driverService.authenticateDriver(body);
  return context.json({ driver }, 200);
}

export async function handleGetOnlineDrivers(context: Context) {
  const list = await driverService.getOnlineDrivers();
  return context.json(list, 200);
}

export async function handleUpdateOnlineStatus(context: Context) {
  const id = context.req.param('id');
  const body = await context.req.json();
  const updated = await driverService.updateOnlineStatus(id, body);
  return context.json(updated, 200);
}

export async function handleGetDriverProfile(context: Context) {
  const id = context.req.param('id');
  const driver = await driverService.getDriverProfile(id);
  return context.json(driver, 200);
}

export async function handleGetDriverStats(context: Context) {
  const id = context.req.param('id');
  const stats = await driverService.getDriverStats(id);
  return context.json(stats, 200);
}

export async function handleGetDriverTripHistory(context: Context) {
  const id = context.req.param('id');
  const trips = await driverService.getDriverTripHistory(id);
  return context.json(trips, 200);
}

export async function handleGetDriverReviews(context: Context) {
  const id = context.req.param('id');
  const reviews = await driverService.getDriverReviews(id);
  return context.json(reviews, 200);
}

export async function handleGetActiveRideRequests(context: Context) {
  const activeRideRequests = await driverService.getActiveRideRequests();
  return context.json(activeRideRequests, 200);
}

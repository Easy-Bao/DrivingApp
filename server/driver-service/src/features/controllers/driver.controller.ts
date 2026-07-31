import { Context } from 'hono';
import { DriverDomainError } from '../entities/driver_operations.types.ts';
import { driverOperationsService, driverService } from '../driver.dependencies.ts';

export async function handleGetOnlineDrivers(context: Context) {
  const list = await driverOperationsService.getOnlineDrivers();
  return context.json(list, 200);
}

export async function handleUpdateOnlineStatus(context: Context) {
  const id = context.req.param('id')!;
  const authenticatedDriverId = context.get('driverId');
  if (authenticatedDriverId !== id) {
    throw new DriverDomainError(403, 'FORBIDDEN', 'Forbidden');
  }
  const body = await context.req.json();
  const updated = await driverOperationsService.updateOnlineStatus(id, body);
  return context.json(updated, 200);
}

export async function handleGetDriverProfile(context: Context) {
  const id = context.req.param('id')!;
  const driver = await driverService.getDriverProfile(id);
  return context.json(driver, 200);
}

export async function handleGetDriverStats(context: Context) {
  const id = context.req.param('id')!;
  const stats = await driverService.getDriverStats(id);
  return context.json(stats, 200);
}

export async function handleGetDriverTripHistory(context: Context) {
  const id = context.req.param('id')!;
  const trips = await driverService.getDriverTripHistory(id);
  return context.json(trips, 200);
}

export async function handleGetDriverReviews(context: Context) {
  const id = context.req.param('id')!;

  if (!id) {
    return context.json({ message: 'Driver ID is required' }, 400);
  }

  const page = parseInt(context.req.query('page') || '1', 10);
  const limit = parseInt(context.req.query('limit') || '5', 10);

  const reviews = await driverService.getDriverReviews(id, page, limit);
  return context.json(reviews, 200);
}

export async function handleGetActiveRideRequests(context: Context) {
  const activeRideRequests = await driverService.getActiveRideRequests();
  return context.json(activeRideRequests, 200);
}

export async function handleAddDriverReview(context: Context) {
  const id = context.req.param('id')!;
  const body = await context.req.json();
  const review = await driverService.addDriverReview(id, body);
  return context.json(review, 201);
}

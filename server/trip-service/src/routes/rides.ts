import { Hono } from 'hono';
import { prisma } from '../db.ts';
import { mapRideToSnakeCase } from '../utils/mappers.ts';
import { fetchPassengerName } from '../services/passenger.ts';
import { acceptRideRequest } from '../services/rides.ts';

const ridesRouter = new Hono();

ridesRouter.post('/', async (c) => {
  try {
    const body = await c.req.json();
    const passengerId = body.passenger_id;
    const passengerName = await fetchPassengerName(passengerId);

    const newRide = await prisma.ride.create({
      data: {
        passengerId,
        passengerName,
        rideType: body.ride_type || 'solo-ride',
        pickupLatitude: parseFloat(body.pickup_latitude),
        pickupLongitude: parseFloat(body.pickup_longitude),
        pickupName: body.pickup_name || 'Pickup Location',
        dropoffLatitude: parseFloat(body.dropoff_latitude),
        dropoffLongitude: parseFloat(body.dropoff_longitude),
        dropoffName: body.dropoff_name || 'Dropoff Location',
        fare: parseFloat(body.fare),
        status: 'requested',
      },
    });
    return c.json(mapRideToSnakeCase(newRide), 201);
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

ridesRouter.get('/active', async (c) => {
  try {
    const list = await prisma.ride.findMany({
      where: { status: 'requested' },
    });
    return c.json(list.map(mapRideToSnakeCase));
  } catch (e: any) {
    return c.json({ error: e.message }, 500);
  }
});

ridesRouter.get('/:id', async (c) => {
  const id = c.req.param('id');
  try {
    const found = await prisma.ride.findUnique({
      where: { id },
    });
    if (!found) {
      return c.json({ error: 'Ride request not found' }, 404);
    }
    return c.json(mapRideToSnakeCase(found));
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

ridesRouter.get('/driver/:driverId', async (c) => {
  const driverId = c.req.param('driverId');
  try {
    const list = await prisma.ride.findMany({
      where: { driverId },
      orderBy: { createdAt: 'desc' },
    });
    return c.json(list.map(mapRideToSnakeCase));
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

ridesRouter.post('/:id/accept', async (c) => {
  const id = c.req.param('id');
  try {
    const body = await c.req.json();
    if (!body.driver_id || !body.driver_name) {
      return c.json({ error: 'driver_id and driver_name are required' }, 400);
    }

    const updated = await acceptRideRequest(id, body);
    return c.json(mapRideToSnakeCase(updated));
  } catch (e: any) {
    if (e.message === 'DRIVER_MAX_CAP_REACHED') {
      return c.json({ error: 'Driver has reached the maximum cap of 5 concurrent accepted ride requests' }, 400);
    }
    if (e.message === 'DRIVER_HAS_ACTIVE_PRIORITY' || e.message === 'CANNOT_ACCEPT_PRIORITY_WITH_ACTIVE_RIDES') {
      return c.json({ error: 'Priority Ride constraints violated' }, 400);
    }
    if (e.message === 'RIDE_NOT_FOUND') {
      return c.json({ error: 'Ride request not found' }, 404);
    }
    return c.json({ error: e.message }, 400);
  }
});

ridesRouter.post('/:id/status', async (c) => {
  const id = c.req.param('id');
  try {
    const { status } = await c.req.json();
    const updated = await prisma.ride.update({
      where: { id },
      data: { status },
    });
    return c.json(mapRideToSnakeCase(updated));
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

export { ridesRouter };

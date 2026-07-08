import { Hono } from 'hono';
import { prisma } from '../db.ts';
import { mapRideToSnakeCase } from '../utils/mappers.ts';
import { fetchPassengerName } from '../services/passenger.ts';
import { acceptRideRequest } from '../services/rides.ts';

const ridesRouter = new Hono();

ridesRouter.post('/', async (context) => {
  try {
    const body = await context.req.json();
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
    return context.json(mapRideToSnakeCase(newRide), 201);
  } catch (error: any) {
    return context.json({ error: error.message }, 400);
  }
});

ridesRouter.get('/active', async (context) => {
  try {
    const list = await prisma.ride.findMany({
      where: { status: 'requested' },
    });
    return context.json(list.map(mapRideToSnakeCase));
  } catch (error: any) {
    return context.json({ error: error.message }, 500);
  }
});

ridesRouter.get('/:id', async (context) => {
  const id = context.req.param('id');
  try {
    const found = await prisma.ride.findUnique({
      where: { id },
    });
    if (!found) {
      return context.json({ error: 'Ride request not found' }, 404);
    }
    return context.json(mapRideToSnakeCase(found));
  } catch (error: any) {
    return context.json({ error: error.message }, 400);
  }
});

ridesRouter.get('/driver/:driverId', async (context) => {
  const driverId = context.req.param('driverId');
  try {
    const list = await prisma.ride.findMany({
      where: { driverId },
      orderBy: { createdAt: 'desc' },
    });
    return context.json(list.map(mapRideToSnakeCase));
  } catch (error: any) {
    return context.json({ error: error.message }, 400);
  }
});

ridesRouter.post('/:id/accept', async (context) => {
  const id = context.req.param('id');
  try {
    const body = await context.req.json();
    if (!body.driver_id || !body.driver_name) {
      return context.json({ error: 'driver_id and driver_name are required' }, 400);
    }

    const updated = await acceptRideRequest(id, body);
    return context.json(mapRideToSnakeCase(updated));
  } catch (error: any) {
    if (error.message === 'DRIVER_MAX_CAP_REACHED') {
      return context.json({ error: 'Driver has reached the maximum cap of 5 concurrent accepted ride requests' }, 400);
    }
    if (error.message === 'DRIVER_HAS_ACTIVE_PRIORITY' || error.message === 'CANNOT_ACCEPT_PRIORITY_WITH_ACTIVE_RIDES') {
      return context.json({ error: 'Priority Ride constraints violated' }, 400);
    }
    if (error.message === 'RIDE_NOT_FOUND') {
      return context.json({ error: 'Ride request not found' }, 404);
    }
    return context.json({ error: error.message }, 400);
  }
});

ridesRouter.post('/:id/status', async (context) => {
  const rideIdentifier = context.req.param('id');
  try {
    const { status: rideStatus } = await context.req.json();
    const isTerminalStatus = rideStatus === 'completed' || rideStatus === 'canceled' || rideStatus === 'cancelled';
    const updatedRideRecord = await prisma.ride.update({
      where: { id: rideIdentifier },
      data: {
        status: rideStatus,
        completedAt: isTerminalStatus ? new Date() : undefined,
      },
    });
    return context.json(mapRideToSnakeCase(updatedRideRecord));
  } catch (caughtError: any) {
    return context.json({ error: caughtError.message }, 400);
  }
});

export { ridesRouter };

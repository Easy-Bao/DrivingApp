/// Trip Service entrypoint using Hono, Prisma, and a snake_case mapper to handle ride lifecycle endpoints.
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { prisma } from './db.ts';

const app = new Hono();

app.use('*', cors());

function mapRideToSnakeCase(ride: any) {
  if (!ride) return null;
  return {
    id: ride.id,
    passenger_id: ride.passengerId,
    passenger_name: ride.passengerName,
    ride_type: ride.rideType,
    pickup_latitude: ride.pickupLatitude,
    pickup_longitude: ride.pickupLongitude,
    pickup_name: ride.pickupName,
    dropoff_latitude: ride.dropoffLatitude,
    dropoff_longitude: ride.dropoffLongitude,
    dropoff_name: ride.dropoffName,
    fare: ride.fare,
    status: ride.status,
    created_at: ride.createdAt instanceof Date ? ride.createdAt.toISOString() : ride.createdAt,
    driver_id: ride.driverId,
    driver_name: ride.driverName,
    driver_rating: ride.driverRating,
    vehicle_type: ride.vehicleType,
    plate_number: ride.plateNumber,
  };
}

app.post('/rides', async (c) => {
  try {
    const body = await c.req.json();
    const passengerId = body.passenger_id;
    let passengerName = 'Passenger';
    try {
      const passengerServiceUrl = process.env.PASSENGER_SERVICE_URL || 'http://127.0.0.1:8081';
      const pRes = await fetch(`${passengerServiceUrl}/passengers/${passengerId}`);
      if (pRes.ok) {
        const passenger = await pRes.json();
        if (passenger && passenger.name) {
          passengerName = passenger.name;
        }
      }
    } catch (err) {
      console.error('Failed to fetch passenger name from passenger-service:', err);
    }
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

app.get('/rides/active', async (c) => {
  try {
    const list = await prisma.ride.findMany({
      where: { status: 'requested' },
    });
    return c.json(list.map(mapRideToSnakeCase));
  } catch (e: any) {
    return c.json({ error: e.message }, 500);
  }
});

app.get('/rides/:id', async (c) => {
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

app.get('/rides/driver/:driverId', async (c) => {
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

app.post('/rides/:id/accept', async (c) => {
  const id = c.req.param('id');
  try {
    const { driver_id, driver_name, driver_rating, vehicle_type, plate_number } = await c.req.json();
    if (!driver_id || !driver_name) {
      return c.json({ error: 'driver_id and driver_name are required' }, 400);
    }

    // Enforce concurrency limit & priority lock constraints
    const activeRides = await prisma.ride.findMany({
      where: {
        driverId: driver_id,
        status: { in: ['accepted', 'arrived', 'in_transit'] },
      },
    });

    if (activeRides.length >= 5) {
      return c.json({ error: 'Driver has reached the maximum cap of 5 concurrent accepted ride requests' }, 400);
    }

    const hasActivePriority = activeRides.some((r) => r.rideType === 'Bao Premium');
    if (hasActivePriority) {
      return c.json({ error: 'Driver has an active Priority Ride and cannot accept other rides' }, 400);
    }

    const targetRide = await prisma.ride.findUnique({ where: { id } });
    if (targetRide && targetRide.rideType === 'Bao Premium' && activeRides.length > 0) {
      return c.json({ error: 'Cannot accept a Priority Ride while having other active rides' }, 400);
    }

    const updated = await prisma.ride.update({
      where: { id },
      data: {
        status: 'accepted',
        driverId: driver_id,
        driverName: driver_name,
        driverRating: driver_rating ?? '5.0',
        vehicleType: vehicle_type ?? 'Unknown',
        plateNumber: plate_number ?? 'Unknown',
      },
    });
    return c.json(mapRideToSnakeCase(updated));
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

app.post('/rides/:id/status', async (c) => {
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

app.get('/', (c) => c.json({ status: 'Trip Service OK' }));

const port = parseInt(process.env.PORT || '8083');

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
};

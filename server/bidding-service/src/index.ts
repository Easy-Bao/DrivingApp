/// Bidding Service: manages passenger fare estimation, bid sessions, and driver offer lifecycle.
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { prisma } from './db.ts';

const app = new Hono();

app.use('*', cors());

const SESSION_TTL_MS =
  parseInt(process.env.SESSION_TTL_MINUTES || '5') * 60 * 1000;

const TRIP_SERVICE_URL =
  process.env.TRIP_SERVICE_URL || 'http://127.0.0.1:8083';

type FareConfig = {
  base: number;
  perKm: number;
  perMin: number;
  minFare: number;
};

const FARE_CONFIGS: Record<string, FareConfig> = {
  'Solo Ride':   { base: 20, perKm: 10, perMin: 1.5, minFare: 25 },
  'Share-Bao':   { base: 15, perKm: 7,  perMin: 1.0, minFare: 18 },
  'Bao Premium': { base: 35, perKm: 15, perMin: 2.0, minFare: 40 },
};

function computeFare(rideType: string, distanceKm: number, durationMinutes: number) {
  const cfg = FARE_CONFIGS[rideType] ?? FARE_CONFIGS['Solo Ride'];
  const distanceCharge = distanceKm * cfg.perKm;
  const timeCharge = durationMinutes * cfg.perMin;
  const subtotal = cfg.base + distanceCharge + timeCharge;
  const rawTotal = Math.max(subtotal, cfg.minFare);
  const totalFare = Math.round(rawTotal * 2) / 2;
  return {
    base_fare: cfg.base,
    distance_charge: parseFloat(distanceCharge.toFixed(2)),
    time_charge: parseFloat(timeCharge.toFixed(2)),
    surge_charge: 0,
    total_fare: totalFare,
  };
}

function mapSession(s: any) {
  return {
    id: s.id,
    passenger_id: s.passengerId,
    ride_type: s.rideType,
    pickup_latitude: s.pickupLatitude,
    pickup_longitude: s.pickupLongitude,
    pickup_name: s.pickupName,
    dropoff_latitude: s.dropoffLatitude,
    dropoff_longitude: s.dropoffLongitude,
    dropoff_name: s.dropoffName,
    distance_km: s.distanceKm,
    duration_minutes: s.durationMinutes,
    offered_fare: s.offeredFare,
    status: s.status,
    accepted_driver_id: s.acceptedDriverId,
    created_at: s.createdAt instanceof Date ? s.createdAt.toISOString() : s.createdAt,
    expires_at: s.expiresAt instanceof Date ? s.expiresAt.toISOString() : s.expiresAt,
  };
}

function mapOffer(o: any) {
  return {
    id: o.id,
    session_id: o.sessionId,
    driver_id: o.driverId,
    driver_name: o.driverName,
    plate_number: o.plateNumber,
    vehicle_type: o.vehicleType,
    proposed_fare: o.proposedFare,
    status: o.status,
    created_at: o.createdAt instanceof Date ? o.createdAt.toISOString() : o.createdAt,
  };
}

app.post('/bids/fare', async (c) => {
  try {
    const { ride_type, distance_km, duration_minutes } = await c.req.json();
    if (distance_km == null || duration_minutes == null) {
      return c.json({ error: 'distance_km and duration_minutes are required' }, 400);
    }
    const breakdown = computeFare(
      ride_type ?? 'Solo Ride',
      parseFloat(distance_km),
      parseFloat(duration_minutes),
    );
    return c.json(breakdown);
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

app.post('/bids', async (c) => {
  try {
    const body = await c.req.json();
    const {
      passenger_id, ride_type,
      pickup_latitude, pickup_longitude, pickup_name,
      dropoff_latitude, dropoff_longitude, dropoff_name,
      distance_km, duration_minutes,
    } = body;

    if (!passenger_id || !ride_type || pickup_latitude == null || dropoff_latitude == null) {
      return c.json({ error: 'passenger_id, ride_type, pickup, and dropoff are required' }, 400);
    }

    const dKm = parseFloat(distance_km ?? 0);
    const dMin = parseFloat(duration_minutes ?? 0);
    const fare = computeFare(ride_type, dKm, dMin);
    const expiresAt = new Date(Date.now() + SESSION_TTL_MS);

    const session = await prisma.bidSession.create({
      data: {
        passengerId: passenger_id,
        rideType: ride_type,
        pickupLatitude: parseFloat(pickup_latitude),
        pickupLongitude: parseFloat(pickup_longitude),
        pickupName: pickup_name ?? 'Pickup',
        dropoffLatitude: parseFloat(dropoff_latitude),
        dropoffLongitude: parseFloat(dropoff_longitude),
        dropoffName: dropoff_name ?? 'Dropoff',
        distanceKm: dKm,
        durationMinutes: dMin,
        offeredFare: fare.total_fare,
        status: 'open',
        expiresAt,
      },
    });

    return c.json(mapSession(session), 201);
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

const PASSENGER_SERVICE_URL = process.env.PASSENGER_SERVICE_URL || 'http://127.0.0.1:8081';

app.get('/bids/active', async (c) => {
  try {
    const driverId = c.req.query('driver_id');
    const now = new Date();

    await prisma.bidSession.updateMany({
      where: { status: 'open', expiresAt: { lt: now } },
      data: { status: 'canceled' },
    });

    const sessions = await prisma.bidSession.findMany({
      where: { status: 'open', expiresAt: { gte: now } },
      orderBy: { createdAt: 'desc' },
      include: { offers: true },
    });

    const visible = driverId
      ? sessions.filter((s) => !s.offers.some((o) => o.driverId === driverId))
      : sessions;

    const mappedSessions = await Promise.all(visible.map(async (s) => {
      let passengerName = 'Passenger';
      let passengerRating = '4.8';
      try {
        const pRes = await fetch(`${PASSENGER_SERVICE_URL}/passengers/${s.passengerId}`);
        if (pRes.ok) {
          const passenger = await pRes.json() as any;
          if (passenger && passenger.name) {
            passengerName = passenger.name;
          }
        }
      } catch (err) {
        console.error('Failed to fetch passenger details in bidding-service:', err);
      }
      
      const ratings = ['4.8', '4.9', '4.7', '5.0', '4.6'];
      const charCodeSum = s.passengerId.split('').reduce((acc: number, char: string) => acc + char.charCodeAt(0), 0);
      passengerRating = ratings[charCodeSum % ratings.length];

      return {
        ...mapSession(s),
        passenger_name: passengerName,
        passenger_rating: passengerRating,
      };
    }));

    return c.json(mappedSessions);
  } catch (e: any) {
    return c.json({ error: e.message }, 500);
  }
});

app.get('/bids/:id/offers', async (c) => {
  const id = c.req.param('id');
  try {
    const offers = await prisma.driverOffer.findMany({
      where: { sessionId: id, status: 'pending' },
      orderBy: { createdAt: 'asc' },
    });
    return c.json(offers.map(mapOffer));
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

app.post('/bids/:id/offer', async (c) => {
  const id = c.req.param('id');
  try {
    const { driver_id, driver_name, plate_number, vehicle_type, proposed_fare } =
      await c.req.json();

    if (!driver_id || !driver_name || !plate_number || !vehicle_type) {
      return c.json({ error: 'driver_id, driver_name, plate_number, and vehicle_type are required' }, 400);
    }

    const session = await prisma.bidSession.findUnique({ where: { id } });
    if (!session) return c.json({ error: 'Bid session not found' }, 404);
    if (session.status !== 'open') {
      return c.json({ error: `Session is ${session.status}` }, 409);
    }
    if (new Date() > session.expiresAt) {
      await prisma.bidSession.update({ where: { id }, data: { status: 'canceled' } });
      return c.json({ error: 'Session has expired' }, 410);
    }

    const existing = await prisma.driverOffer.findFirst({
      where: { sessionId: id, driverId: driver_id, status: 'pending' },
    });
    if (existing) return c.json({ error: 'Offer already placed' }, 409);

    // Concurrency and Priority ride checking
    try {
      const activeRidesRes = await fetch(`${TRIP_SERVICE_URL}/rides/driver/${driver_id}`);
      if (activeRidesRes.ok) {
        const rides = await activeRidesRes.json() as any[];
        const activeRides = rides.filter((r) =>
          r.status === 'accepted' || r.status === 'arrived' || r.status === 'in_transit'
        );

        if (activeRides.length >= 5) {
          return c.json({ error: 'Driver has reached the maximum cap of 5 concurrent accepted ride requests' }, 400);
        }

        const hasActivePriority = activeRides.some((r) => r.ride_type === 'Bao Premium');
        if (hasActivePriority) {
          return c.json({ error: 'Driver has an active Priority Ride and cannot accept other rides' }, 400);
        }

        if (session.rideType === 'Bao Premium' && activeRides.length > 0) {
          return c.json({ error: 'Cannot accept a Priority Ride while having other active rides' }, 400);
        }
      }
    } catch (err) {
      console.error('Failed to enforce active trip constraints in bidding-service:', err);
    }

    const fare = proposed_fare != null
      ? parseFloat(proposed_fare)
      : session.offeredFare;

    const offer = await prisma.driverOffer.create({
      data: {
        sessionId: id,
        driverId: driver_id,
        driverName: driver_name,
        plateNumber: plate_number,
        vehicleType: vehicle_type,
        proposedFare: fare,
        status: 'pending',
      },
    });

    return c.json(mapOffer(offer), 201);
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

app.post('/bids/:id/accept', async (c) => {
  const id = c.req.param('id');
  try {
    const { offer_id } = await c.req.json();
    if (!offer_id) return c.json({ error: 'offer_id is required' }, 400);

    const session = await prisma.bidSession.findUnique({
      where: { id },
      include: { offers: true },
    });
    if (!session) return c.json({ error: 'Bid session not found' }, 404);
    if (session.status !== 'open') {
      return c.json({ error: `Session is already ${session.status}` }, 409);
    }

    const offer = session.offers.find((o) => o.id === offer_id && o.status === 'pending');
    if (!offer) return c.json({ error: 'Offer not found or already resolved' }, 404);

    const tripRes = await fetch(`${TRIP_SERVICE_URL}/rides`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        passenger_id: session.passengerId,
        ride_type: session.rideType,
        pickup_latitude: session.pickupLatitude,
        pickup_longitude: session.pickupLongitude,
        pickup_name: session.pickupName,
        dropoff_latitude: session.dropoffLatitude,
        dropoff_longitude: session.dropoffLongitude,
        dropoff_name: session.dropoffName,
        fare: offer.proposedFare,
      }),
    });

    if (!tripRes.ok) {
      const errBody = await tripRes.json() as any;
      return c.json({ error: 'Failed to create trip', details: errBody }, 502);
    }

    const trip = await tripRes.json() as any;

    await tripRes.body?.cancel().catch(() => {});

    const [updatedSession] = await prisma.$transaction([
      prisma.bidSession.update({
        where: { id },
        data: { status: 'accepted', acceptedDriverId: offer.driverId },
      }),
      prisma.driverOffer.update({
        where: { id: offer_id },
        data: { status: 'accepted' },
      }),
      prisma.driverOffer.updateMany({
        where: { sessionId: id, id: { not: offer_id }, status: 'pending' },
        data: { status: 'rejected' },
      }),
    ]);

    await fetch(`${TRIP_SERVICE_URL}/rides/${trip.id}/accept`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        driver_id: offer.driverId,
        driver_name: offer.driverName,
        vehicle_type: offer.vehicleType,
        plate_number: offer.plateNumber,
      }),
    }).catch(() => {});

    return c.json({
      session: mapSession(updatedSession),
      offer: mapOffer(offer),
      ride_id: trip.id,
    });
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

app.delete('/bids/:id', async (c) => {
  const id = c.req.param('id');
  try {
    const session = await prisma.bidSession.findUnique({ where: { id } });
    if (!session) return c.json({ error: 'Bid session not found' }, 404);
    if (session.status === 'accepted') {
      return c.json({ error: 'Cannot cancel an accepted session' }, 409);
    }
    const updated = await prisma.bidSession.update({
      where: { id },
      data: { status: 'canceled' },
    });
    return c.json(mapSession(updated));
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

app.post('/bids/:id/cancel-offer', async (c) => {
  const id = c.req.param('id');
  try {
    const { driver_id } = await c.req.json();
    if (!driver_id) return c.json({ error: 'driver_id is required' }, 400);

    const offer = await prisma.driverOffer.findFirst({
      where: { sessionId: id, driverId: driver_id, status: 'pending' },
    });
    if (!offer) return c.json({ error: 'No pending offer found for this driver' }, 404);

    const updated = await prisma.driverOffer.update({
      where: { id: offer.id },
      data: { status: 'rejected' },
    });
    return c.json(mapOffer(updated));
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

app.get('/bids/:id', async (c) => {
  const id = c.req.param('id');
  try {
    const session = await prisma.bidSession.findUnique({
      where: { id },
      include: { offers: true },
    });
    if (!session) return c.json({ error: 'Bid session not found' }, 404);
    return c.json({
      ...mapSession(session),
      offers: session.offers.map(mapOffer),
    });
  } catch (e: any) {
    return c.json({ error: e.message }, 400);
  }
});

app.get('/', (c) => c.json({ status: 'Bidding Service OK' }));

const port = parseInt(process.env.PORT || '8084');
console.log(`Bidding Service listening on port ${port}`);

export default {
  port,
  fetch: app.fetch,
};

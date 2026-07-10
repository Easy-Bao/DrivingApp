import { prisma } from '../db.ts';

const SESSION_TTL_MS = parseInt(process.env.SESSION_TTL_MINUTES || '5') * 60 * 1000;
const TRIP_SERVICE_URL = process.env.TRIP_SERVICE_URL || 'http://127.0.0.1:8083';
const PASSENGER_SERVICE_URL = process.env.PASSENGER_SERVICE_URL || 'http://127.0.0.1:8081';

type FareConfig = {
  base: number;
  perKm: number;
  perMin: number;
  minFare: number;
};

const FARE_CONFIGS: Record<string, FareConfig> = {
  'Solo Ride': { base: 20, perKm: 10, perMin: 1.5, minFare: 25 },
  'Share-Bao': { base: 15, perKm: 7, perMin: 1.0, minFare: 18 },
  'Bao Premium': { base: 35, perKm: 15, perMin: 2.0, minFare: 40 },
};

export function computeFare(rideType: string, distanceKm: number, durationMinutes: number) {
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

export async function createBidSession(data: any) {
  const {
    passenger_id,
    ride_type,
    pickup_latitude,
    pickup_longitude,
    pickup_name,
    dropoff_latitude,
    dropoff_longitude,
    dropoff_name,
    distance_km,
    duration_minutes,
    target_driver_id,
  } = data;

  const dKm = parseFloat(distance_km ?? 0);
  const dMin = parseFloat(duration_minutes ?? 0);
  const fare = computeFare(ride_type, dKm, dMin);
  const expiresAt = new Date(Date.now() + SESSION_TTL_MS);

  return await prisma.bidSession.create({
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
      targetDriverId: target_driver_id ?? null,
      status: 'open',
      expiresAt,
    },
  });
}

export async function getActiveBidSessions(driverId?: string) {
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

  // Filter sessions so a driver only sees open sessions that are either public (no target)
  // or specifically directed/booked for their driver ID.
  const visible = driverId
    ? sessions.filter((s) => {
        if (s.targetDriverId && s.targetDriverId !== driverId) {
          return false;
        }
        return !s.offers.some((o) => o.driverId === driverId);
      })
    : sessions;

  return await Promise.all(visible.map(async (s) => {
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
      ...s,
      passengerName,
      passengerRating,
    };
  }));
}

export async function getOffers(sessionId: string) {
  return await prisma.driverOffer.findMany({
    where: { sessionId, status: 'pending' },
    orderBy: { createdAt: 'asc' },
  });
}

export async function placeOffer(sessionId: string, offerData: any) {
  const { driver_id, driver_name, plate_number, vehicle_type, proposed_fare } = offerData;

  const session = await prisma.bidSession.findUnique({ where: { id: sessionId } });
  if (!session) {
    throw new Error('Bid session not found');
  }
  if (session.status !== 'open') {
    throw new Error(`Session is ${session.status}`);
  }
  if (new Date() > session.expiresAt) {
    await prisma.bidSession.update({ where: { id: sessionId }, data: { status: 'canceled' } });
    throw new Error('Session has expired');
  }

  const existing = await prisma.driverOffer.findFirst({
    where: { sessionId, driverId: driver_id, status: 'pending' },
  });
  if (existing) {
    throw new Error('Offer already placed');
  }

  try {
    const activeRidesRes = await fetch(`${TRIP_SERVICE_URL}/rides/driver/${driver_id}`);
    if (activeRidesRes.ok) {
      const rides = await activeRidesRes.json() as any[];
      const activeRides = rides.filter((r) =>
        r.status === 'accepted' || r.status === 'arrived' || r.status === 'in_transit'
      );

      if (activeRides.length >= 5) {
        throw new Error('Driver has reached the maximum cap of 5 concurrent accepted ride requests');
      }

      const hasActivePriority = activeRides.some((r) => r.ride_type === 'Bao Premium');
      if (hasActivePriority) {
        throw new Error('Driver has an active Priority Ride and cannot accept other rides');
      }

      if (session.rideType === 'Bao Premium' && activeRides.length > 0) {
        throw new Error('Cannot accept a Priority Ride while having other active rides');
      }
    }
  } catch (err: any) {
    if (err.message && err.message.includes('Driver has')) {
      throw err;
    }
    console.error('Failed to enforce active trip constraints in bidding-service:', err);
  }

  const fare = proposed_fare != null
    ? parseFloat(proposed_fare)
    : session.offeredFare;

  return await prisma.driverOffer.create({
    data: {
      sessionId,
      driverId: driver_id,
      driverName: driver_name,
      plateNumber: plate_number,
      vehicleType: vehicle_type,
      proposedFare: fare,
      status: 'pending',
    },
  });
}

export async function acceptOffer(sessionId: string, offerId: string) {
  const session = await prisma.bidSession.findUnique({
    where: { id: sessionId },
    include: { offers: true },
  });
  if (!session) {
    throw new Error('Bid session not found');
  }
  if (session.status !== 'open') {
    throw new Error(`Session is already ${session.status}`);
  }

  const offer = session.offers.find((o) => o.id === offerId && o.status === 'pending');
  if (!offer) {
    throw new Error('Offer not found or already resolved');
  }

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
    throw new Error('Failed to create trip: ' + JSON.stringify(errBody));
  }

  const trip = await tripRes.json() as any;
  await tripRes.body?.cancel().catch(() => { });

  const [updatedSession] = await prisma.$transaction([
    prisma.bidSession.update({
      where: { id: sessionId },
      data: { status: 'accepted', acceptedDriverId: offer.driverId },
    }),
    prisma.driverOffer.update({
      where: { id: offerId },
      data: { status: 'accepted' },
    }),
    prisma.driverOffer.updateMany({
      where: { sessionId, id: { not: offerId }, status: 'pending' },
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
  }).catch(() => { });

  return {
    session: updatedSession,
    offer,
    rideId: trip.id,
  };
}

export async function cancelBidSession(sessionId: string) {
  const session = await prisma.bidSession.findUnique({ where: { id: sessionId } });
  if (!session) {
    throw new Error('Bid session not found');
  }
  if (session.status === 'accepted') {
    throw new Error('Cannot cancel an accepted session');
  }
  return await prisma.bidSession.update({
    where: { id: sessionId },
    data: { status: 'canceled' },
  });
}

export async function cancelOffer(sessionId: string, driverId: string) {
  const offer = await prisma.driverOffer.findFirst({
    where: { sessionId, driverId, status: 'pending' },
  });
  if (!offer) {
    throw new Error('No pending offer found for this driver');
  }
  return await prisma.driverOffer.update({
    where: { id: offer.id },
    data: { status: 'rejected' },
  });
}

export async function getBidSession(sessionId: string) {
  const session = await prisma.bidSession.findUnique({
    where: { id: sessionId },
    include: { offers: true },
  });
  if (!session) {
    throw new Error('Bid session not found');
  }
  return session;
}

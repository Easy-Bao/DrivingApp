/**
 * Service layer orchestrating domain logic for fare calculations, active sessions, driver offers, and trip service merges.
 */
import { BiddingRepository } from '../entities/bidding.types.ts';
import { CreateBidSessionSchema, PlaceOfferSchema } from '../schemas/bidding.schema.ts';
import { HTTPException } from 'hono/http-exception';
import { Logger } from '../../../shared/logger/logger.ts';

const SESSION_TTL_MS = parseInt(process.env.SESSION_TTL_MINUTES || '5') * 60 * 1000;
if (!process.env.TRIP_SERVICE_URL) {
  throw new Error("Configuration Error: TRIP_SERVICE_URL is required but not set.");
}
if (!process.env.PASSENGER_SERVICE_URL) {
  throw new Error("Configuration Error: PASSENGER_SERVICE_URL is required but not set.");
}
const TRIP_SERVICE_URL = process.env.TRIP_SERVICE_URL;
const PASSENGER_SERVICE_URL = process.env.PASSENGER_SERVICE_URL;

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

export class BiddingService {
  private repository: BiddingRepository;

  constructor(repository: BiddingRepository) {
    this.repository = repository;
  }

  computeFareAmount(rideType: string, distanceKm: number, durationMinutes: number) {
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

  async createSession(payload: any) {
    const dKm = parseFloat(payload.distance_km ?? 0);
    const dMin = parseFloat(payload.duration_minutes ?? 0);
    const fare = this.computeFareAmount(payload.ride_type, dKm, dMin);
    const expiresAt = new Date(Date.now() + SESSION_TTL_MS);

    return await this.repository.createSession({
      passengerId: payload.passenger_id,
      rideType: payload.ride_type,
      pickupLatitude: parseFloat(payload.pickup_latitude),
      pickupLongitude: parseFloat(payload.pickup_longitude),
      pickupName: payload.pickup_name ?? 'Pickup',
      dropoffLatitude: parseFloat(payload.dropoff_latitude),
      dropoffLongitude: parseFloat(payload.dropoff_longitude),
      dropoffName: payload.dropoff_name ?? 'Dropoff',
      distanceKm: dKm,
      durationMinutes: dMin,
      offeredFare: fare.total_fare,
      targetDriverId: payload.target_driver_id ?? null,
      expiresAt,
    });
  }

  async getActiveSessions(driverId?: string) {
    const now = new Date();
    await this.repository.expireSessions(now);

    const sessions = await this.repository.findActiveSessions(now);

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
        Logger.error('Failed to fetch passenger details in bidding-service:', err);
      }

      const ratings = ['4.8', '4.9', '4.7', '5.0', '4.6'];
      const charCodeSum = s.passengerId.split('').reduce((acc: number, char: string) => acc + char.charCodeAt(0), 0);
      passengerRating = ratings[charCodeSum % ratings.length];

      return {
        id: s.id,
        passenger_id: s.passengerId,
        passengerName,
        passengerRating,
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
        target_driver_id: s.targetDriverId,
        expires_at: s.expiresAt.toISOString(),
        created_at: s.createdAt.toISOString(),
      };
    }));
  }

  async getOffers(sessionId: string) {
    const list = await this.repository.findOffersBySessionId(sessionId);
    return list.map(o => ({
      id: o.id,
      session_id: o.sessionId,
      driver_id: o.driverId,
      driver_name: o.driverName,
      plate_number: o.plateNumber,
      vehicle_type: o.vehicleType,
      proposed_fare: o.proposedFare,
      status: o.status,
      created_at: o.createdAt.toISOString(),
    }));
  }

  async placeOffer(sessionId: string, offerData: any) {
    const session = await this.repository.findSessionById(sessionId);
    if (!session) {
      throw new HTTPException(404, { message: 'Bid session not found' });
    }
    if (session.status !== 'open') {
      throw new HTTPException(400, { message: `Session is ${session.status}` });
    }
    if (new Date() > session.expiresAt) {
      await this.repository.updateSessionStatus(sessionId, 'canceled');
      throw new HTTPException(400, { message: 'Session has expired' });
    }

    const existing = await this.repository.findPendingOffer(sessionId, offerData.driver_id);
    if (existing) {
      throw new HTTPException(400, { message: 'Offer already placed' });
    }

    try {
      const activeRidesRes = await fetch(`${TRIP_SERVICE_URL}/rides/driver/${offerData.driver_id}`);
      if (activeRidesRes.ok) {
        const rides = await activeRidesRes.json() as any[];
        const activeRides = rides.filter((r) =>
          r.status === 'accepted' || r.status === 'arrived' || r.status === 'in_transit'
        );

        if (activeRides.length >= 5) {
          throw new HTTPException(400, { message: 'Driver has reached the maximum cap of 5 concurrent accepted ride requests' });
        }

        const hasActivePriority = activeRides.some((r) => r.ride_type === 'Bao Premium');
        if (hasActivePriority) {
          throw new HTTPException(400, { message: 'Driver has an active Priority Ride and cannot accept other rides' });
        }

        if (session.rideType === 'Bao Premium' && activeRides.length > 0) {
          throw new HTTPException(400, { message: 'Cannot accept a Priority Ride while having other active rides' });
        }
      }
    } catch (err: any) {
      if (err instanceof HTTPException) throw err;
      Logger.error('Failed to enforce active trip constraints in bidding-service:', err);
    }

    const fare = offerData.proposed_fare != null
      ? parseFloat(offerData.proposed_fare)
      : session.offeredFare;

    const offer = await this.repository.createOffer(sessionId, {
      driverId: offerData.driver_id,
      driverName: offerData.driver_name,
      plateNumber: offerData.plate_number,
      vehicleType: offerData.vehicle_type,
      proposedFare: fare,
    });

    return {
      id: offer.id,
      session_id: offer.sessionId,
      driver_id: offer.driverId,
      driver_name: offer.driverName,
      plate_number: offer.plateNumber,
      vehicle_type: offer.vehicleType,
      proposed_fare: offer.proposedFare,
      status: offer.status,
      created_at: offer.createdAt.toISOString(),
    };
  }

  async acceptOffer(sessionId: string, offerId: string) {
    const session = await this.repository.findSessionWithOffers(sessionId);
    if (!session) {
      throw new HTTPException(404, { message: 'Bid session not found' });
    }
    if (session.status !== 'open') {
      throw new HTTPException(400, { message: `Session is already ${session.status}` });
    }

    const offer = session.offers.find((o) => o.id === offerId && o.status === 'pending');
    if (!offer) {
      throw new HTTPException(404, { message: 'Offer not found or already resolved' });
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
      throw new HTTPException(500, { message: 'Failed to create trip: ' + JSON.stringify(errBody) });
    }

    const trip = await tripRes.json() as any;
    await tripRes.body?.cancel().catch(() => { });

    const result = await this.repository.acceptOfferTransaction(sessionId, offerId, offer.driverId);

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
      session: {
        id: result.session.id,
        passenger_id: result.session.passengerId,
        status: result.session.status,
        accepted_driver_id: result.session.acceptedDriverId,
      },
      offer: {
        id: result.offer.id,
        driver_id: result.offer.driverId,
        status: result.offer.status,
      },
      rideId: trip.id,
    };
  }

  async cancelSession(sessionId: string) {
    const session = await this.repository.findSessionById(sessionId);
    if (!session) {
      throw new HTTPException(404, { message: 'Bid session not found' });
    }
    if (session.status === 'accepted') {
      throw new HTTPException(400, { message: 'Cannot cancel an accepted session' });
    }
    const updated = await this.repository.updateSessionStatus(sessionId, 'canceled');
    return {
      id: updated.id,
      passenger_id: updated.passengerId,
      status: updated.status,
    };
  }

  async cancelOffer(sessionId: string, driverId: string) {
    const offer = await this.repository.findPendingOffer(sessionId, driverId);
    if (!offer) {
      throw new HTTPException(404, { message: 'No pending offer found for this driver' });
    }
    const updated = await this.repository.updateOfferStatus(offer.id, 'rejected');
    return {
      id: updated.id,
      session_id: updated.sessionId,
      driver_id: updated.driverId,
      status: updated.status,
    };
  }

  async getSessionDetails(sessionId: string) {
    const session = await this.repository.findSessionWithOffers(sessionId);
    if (!session) {
      throw new HTTPException(404, { message: 'Bid session not found' });
    }
    return {
      id: session.id,
      passenger_id: session.passengerId,
      ride_type: session.rideType,
      pickup_latitude: session.pickupLatitude,
      pickup_longitude: session.pickupLongitude,
      pickup_name: session.pickupName,
      dropoff_latitude: session.dropoffLatitude,
      dropoff_longitude: session.dropoffLongitude,
      dropoff_name: session.dropoffName,
      distance_km: session.distanceKm,
      duration_minutes: session.durationMinutes,
      offered_fare: session.offeredFare,
      status: session.status,
      target_driver_id: session.targetDriverId,
      expires_at: session.expiresAt.toISOString(),
      created_at: session.createdAt.toISOString(),
      offers: session.offers.map((o) => ({
        id: o.id,
        session_id: o.sessionId,
        driver_id: o.driverId,
        driver_name: o.driverName,
        plate_number: o.plateNumber,
        vehicle_type: o.vehicleType,
        proposed_fare: o.proposedFare,
        status: o.status,
        created_at: o.createdAt.toISOString(),
      })),
    };
  }
}

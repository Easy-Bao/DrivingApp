/**
 * Orchestrates the bidding session lifecycle: fare negotiation, session/offer CRUD, and the
 * distributed accept flow. Network calls are fully delegated to PassengerClient and TripClient;
 * pricing math to computeFareAmount. This class owns only domain-state transitions.
 */
import { BiddingRepository } from '../entities/bidding.types.ts';
import { HTTPException } from 'hono/http-exception';
import { Logger } from '../../../shared/logger/logger.ts';
import { computeFareAmount } from '../pricing/bidding.pricing.ts';
import { PassengerClient, TripClient } from '../clients/bidding.clients.ts';

const SESSION_TTL_MS = parseInt(process.env.SESSION_TTL_MINUTES || '5') * 60 * 1000;

export class BiddingService {
  private readonly repository: BiddingRepository;
  private readonly passengerClient: PassengerClient;
  private readonly tripClient: TripClient;

  constructor(repository: BiddingRepository) {
    const passengerServiceUrl = process.env.PASSENGER_SERVICE_URL;
    const tripServiceUrl = process.env.TRIP_SERVICE_URL;

    if (!passengerServiceUrl) {
      throw new Error('Configuration Error: PASSENGER_SERVICE_URL is required but not set.');
    }
    if (!tripServiceUrl) {
      throw new Error('Configuration Error: TRIP_SERVICE_URL is required but not set.');
    }

    this.repository = repository;
    this.passengerClient = new PassengerClient(passengerServiceUrl);
    this.tripClient = new TripClient(tripServiceUrl);
  }

  computeFare(rideType: string, distanceKm: number, durationMinutes: number) {
    return computeFareAmount(rideType, distanceKm, durationMinutes);
  }

  async createSession(payload: any) {
    const distanceKm = parseFloat(payload.distance_km ?? 0);
    const durationMinutes = parseFloat(payload.duration_minutes ?? 0);
    const fare = computeFareAmount(payload.ride_type, distanceKm, durationMinutes);
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
      distanceKm,
      durationMinutes,
      offeredFare: fare.total_fare,
      targetDriverId: payload.target_driver_id ?? null,
      expiresAt,
    });
  }

  async getActiveSessions(driverId?: string) {
    const now = new Date();
    const sessions = await this.repository.findActiveSessions(now);

    // Filter so a driver only sees sessions that are either public or directed at them,
    // and excludes sessions for which they have already placed an offer.
    const visibleSessions = driverId
      ? sessions.filter((session) => {
          if (session.targetDriverId && session.targetDriverId !== driverId) {
            return false;
          }
          return !session.offers.some((offer) => offer.driverId === driverId);
        })
      : sessions;

    const passengerIds = [...new Set(visibleSessions.map((session) => session.passengerId))];
    const passengerMap = await this.passengerClient.fetchPassengersBatch(passengerIds);

    return visibleSessions.map((session) => {
      const passenger = passengerMap[session.passengerId];
      return {
        id: session.id,
        passenger_id: session.passengerId,
        passengerName: passenger?.name ?? 'Passenger',
        passengerRating: passenger?.rating ?? '4.8',
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
      };
    });
  }

  async getOffers(sessionId: string) {
    const offerList = await this.repository.findOffersBySessionId(sessionId);
    return offerList.map((offer) => ({
      id: offer.id,
      session_id: offer.sessionId,
      driver_id: offer.driverId,
      driver_name: offer.driverName,
      plate_number: offer.plateNumber,
      vehicle_type: offer.vehicleType,
      proposed_fare: offer.proposedFare,
      status: offer.status,
      created_at: offer.createdAt.toISOString(),
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

    const existingOffer = await this.repository.findPendingOffer(sessionId, offerData.driver_id);
    if (existingOffer) {
      throw new HTTPException(400, { message: 'Offer already placed' });
    }

    // Enforce driver concurrency caps before persisting the offer.
    try {
      const activeRides = await this.tripClient.fetchDriverActiveRides(offerData.driver_id);
      if (activeRides.length >= 5) {
        throw new HTTPException(400, {
          message: 'Driver has reached the maximum cap of 5 concurrent accepted ride requests',
        });
      }
      const hasActivePriorityRide = activeRides.some((ride) => ride.ride_type === 'Bao Premium');
      if (hasActivePriorityRide) {
        throw new HTTPException(400, {
          message: 'Driver has an active Priority Ride and cannot accept other rides',
        });
      }
      if (session.rideType === 'Bao Premium' && activeRides.length > 0) {
        throw new HTTPException(400, {
          message: 'Cannot accept a Priority Ride while having other active rides',
        });
      }
    } catch (err: any) {
      if (err instanceof HTTPException) throw err;
      Logger.error('Failed to enforce active trip constraints in bidding-service:', err);
    }

    const proposedFare = offerData.proposed_fare != null
      ? parseFloat(offerData.proposed_fare)
      : session.offeredFare;

    const offer = await this.repository.createOffer(sessionId, {
      driverId: offerData.driver_id,
      driverName: offerData.driver_name,
      plateNumber: offerData.plate_number,
      vehicleType: offerData.vehicle_type,
      proposedFare: proposedFare,
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

    const winningOffer = session.offers.find(
      (offer) => offer.id === offerId && offer.status === 'pending'
    );
    if (!winningOffer) {
      throw new HTTPException(404, { message: 'Offer not found or already resolved' });
    }

    // Create the remote ride record first so we obtain a trip ID, then commit the local
    // state transition. If the local commit fails, we issue a compensating cancel to the
    // trip service to prevent a phantom ride from persisting there (Saga rollback).
    const trip = await this.tripClient.createRide({
      passenger_id: session.passengerId,
      ride_type: session.rideType,
      pickup_latitude: session.pickupLatitude,
      pickup_longitude: session.pickupLongitude,
      pickup_name: session.pickupName,
      dropoff_latitude: session.dropoffLatitude,
      dropoff_longitude: session.dropoffLongitude,
      dropoff_name: session.dropoffName,
      fare: winningOffer.proposedFare,
    });

    if (!trip) {
      throw new HTTPException(500, { message: 'Failed to create trip on trip service' });
    }

    let localResult: any;
    try {
      localResult = await this.repository.acceptOfferTransaction(
        sessionId,
        offerId,
        winningOffer.driverId
      );
    } catch (localErr) {
      Logger.error(`acceptOfferTransaction failed for session ${sessionId}; rolling back trip ${trip.id}:`, localErr);
      await this.tripClient.cancelRide(trip.id);
      throw new HTTPException(500, { message: 'Failed to finalise bid acceptance; trip rolled back' });
    }

    // Non-fatal: assigns driver to the trip record. A failure here leaves the ride in a
    // created-but-unassigned state, which can be resolved by a re-drive or admin action.
    await this.tripClient.acceptRide(trip.id, {
      driver_id: winningOffer.driverId,
      driver_name: winningOffer.driverName,
      vehicle_type: winningOffer.vehicleType,
      plate_number: winningOffer.plateNumber,
    });

    return {
      session: {
        id: localResult.session.id,
        passenger_id: localResult.session.passengerId,
        status: localResult.session.status,
        accepted_driver_id: localResult.session.acceptedDriverId,
      },
      offer: {
        id: localResult.offer.id,
        driver_id: localResult.offer.driverId,
        status: localResult.offer.status,
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
    const pendingOffer = await this.repository.findPendingOffer(sessionId, driverId);
    if (!pendingOffer) {
      throw new HTTPException(404, { message: 'No pending offer found for this driver' });
    }
    const updated = await this.repository.updateOfferStatus(pendingOffer.id, 'rejected');
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
      offers: session.offers.map((offer) => ({
        id: offer.id,
        session_id: offer.sessionId,
        driver_id: offer.driverId,
        driver_name: offer.driverName,
        plate_number: offer.plateNumber,
        vehicle_type: offer.vehicleType,
        proposed_fare: offer.proposedFare,
        status: offer.status,
        created_at: offer.createdAt.toISOString(),
      })),
    };
  }
}

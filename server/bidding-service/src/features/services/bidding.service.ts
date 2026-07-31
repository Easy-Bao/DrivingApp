/**
 * Orchestrates bid state while delegating identity, eligibility, zone, fare, and trip
 * authority to their owning services.
 */
import { HTTPException } from 'hono/http-exception';
import { Logger } from '../../shared/logger/logger.ts';
import {
  AdminClient,
  DriverClient,
  FareClient,
  PassengerClient,
  ServiceClientError,
  TripClient,
} from '../clients/bidding.clients.ts';
import {
  BidSession,
  BiddingRepository,
  DriverOffer,
} from '../entities/bidding.types.ts';

const SESSION_TTL_MS = parseInt(process.env.SESSION_TTL_MINUTES || '5') * 60 * 1000;

export type BiddingServiceClients = {
  passengerClient: Pick<
    PassengerClient,
    'checkRideAccess' | 'fetchPassengersBatch'
  >;
  tripClient: Pick<
    TripClient,
    'acceptRide' | 'cancelRide' | 'createRide' | 'fetchDriverActiveRides'
  >;
  driverClient: Pick<DriverClient, 'checkEligibility' | 'fetchProfile'>;
  adminClient: Pick<AdminClient, 'checkZones' | 'currentCommission'>;
  fareClient: Pick<FareClient, 'estimateFare'>;
};

function requiredEnvironment(name: string): string {
  const value = process.env[name];
  if (!value?.trim()) {
    throw new Error(`Configuration Error: ${name} is required but not set.`);
  }
  return value;
}

export class BiddingService {
  private readonly repository: BiddingRepository;
  private readonly passengerClient: BiddingServiceClients['passengerClient'];
  private readonly tripClient: BiddingServiceClients['tripClient'];
  private readonly driverClient: BiddingServiceClients['driverClient'];
  private readonly adminClient: BiddingServiceClients['adminClient'];
  private readonly fareClient: BiddingServiceClients['fareClient'];

  constructor(
    repository: BiddingRepository,
    clients?: BiddingServiceClients,
  ) {
    this.repository = repository;
    const dependencies = clients ?? {
      passengerClient: new PassengerClient(requiredEnvironment('PASSENGER_SERVICE_URL')),
      tripClient: new TripClient(requiredEnvironment('TRIP_SERVICE_URL')),
      driverClient: new DriverClient(requiredEnvironment('DRIVER_SERVICE_URL')),
      adminClient: new AdminClient(requiredEnvironment('ADMIN_SERVICE_URL')),
      fareClient: new FareClient(requiredEnvironment('FARE_SERVICE_URL')),
    };
    this.passengerClient = dependencies.passengerClient;
    this.tripClient = dependencies.tripClient;
    this.driverClient = dependencies.driverClient;
    this.adminClient = dependencies.adminClient;
    this.fareClient = dependencies.fareClient;
  }

  private throwPublicError(error: unknown): never {
    if (error instanceof HTTPException) throw error;
    if (error instanceof ServiceClientError) {
      if (['ACCOUNT_RESTRICTED', 'OUTSIDE_SERVICE_ZONE', 'SERVICE_ZONE_NOT_CONFIGURED']
        .includes(error.code)) {
        throw new HTTPException(403, { message: error.code });
      }
      if (error.code.endsWith('_NOT_FOUND') || error.code === 'FARE_RULE_NOT_FOUND') {
        throw new HTTPException(404, { message: error.code });
      }
      if ([
        'DRIVER_NOT_APPROVED',
        'DRIVER_DOCUMENTS_INCOMPLETE',
        'INSUFFICIENT_CREDIT',
      ].includes(error.code)) {
        throw new HTTPException(409, { message: error.code });
      }
      throw new HTTPException(503, { message: `${error.service.toUpperCase()}_SERVICE_UNAVAILABLE` });
    }
    Logger.error('Bidding operation failed:', error);
    throw new HTTPException(500, { message: 'BIDDING_OPERATION_FAILED' });
  }

  private formatOffer(offer: DriverOffer) {
    return {
      id: offer.id,
      session_id: offer.sessionId,
      driver_id: offer.driverId,
      driver_name: offer.driverName,
      plate_number: offer.plateNumber,
      vehicle_type: offer.vehicleType,
      proposed_fare: offer.proposedFareCentavos / 100,
      proposed_fare_centavos: offer.proposedFareCentavos,
      status: offer.status,
      created_at: offer.createdAt.toISOString(),
    };
  }

  private formatAssignment(
    session: BidSession,
    offer: DriverOffer,
  ) {
    return {
      session: {
        id: session.id,
        passenger_id: session.passengerId,
        status: session.status,
        accepted_driver_id: session.acceptedDriverId,
        assignment_source: session.assignmentSource,
        assigned_by_admin_id: session.assignedByAdminId,
      },
      offer: {
        id: offer.id,
        driver_id: offer.driverId,
        status: offer.status,
      },
      rideId: session.acceptedTripId,
    };
  }

  async computeFare(
    rideType: string,
    distanceKm: number,
    durationMinutes: number,
  ) {
    try {
      const result = await this.fareClient.estimateFare(
        rideType,
        distanceKm,
        durationMinutes,
      );
      return result.estimate;
    } catch (error) {
      this.throwPublicError(error);
    }
  }

  async createSession(payload: any, passengerId: string) {
    const distanceKm = Number(payload.distance_km);
    const durationMinutes = Number(payload.duration_minutes);
    try {
      const [, , fare] = await Promise.all([
        this.passengerClient.checkRideAccess(passengerId),
        this.adminClient.checkZones({
          pickup_latitude: Number(payload.pickup_latitude),
          pickup_longitude: Number(payload.pickup_longitude),
          dropoff_latitude: Number(payload.dropoff_latitude),
          dropoff_longitude: Number(payload.dropoff_longitude),
        }),
        this.fareClient.estimateFare(
          payload.ride_type,
          distanceKm,
          durationMinutes,
        ),
      ]);
      return await this.repository.createSession({
        passengerId,
        rideType: payload.ride_type,
        pickupLatitude: Number(payload.pickup_latitude),
        pickupLongitude: Number(payload.pickup_longitude),
        pickupName: payload.pickup_name ?? 'Pickup',
        dropoffLatitude: Number(payload.dropoff_latitude),
        dropoffLongitude: Number(payload.dropoff_longitude),
        dropoffName: payload.dropoff_name ?? 'Dropoff',
        distanceKm,
        durationMinutes,
        offeredFare: fare.amount,
        offeredFareCentavos: Math.round(fare.amount * 100),
        targetDriverId: payload.target_driver_id ?? null,
        expiresAt: new Date(Date.now() + SESSION_TTL_MS),
      });
    } catch (error) {
      this.throwPublicError(error);
    }
  }

  async getActiveSessions(driverId?: string, includeTargeted = false) {
    const sessions = await this.repository.findActiveSessions(new Date());
    const visibleSessions = driverId
      ? sessions.filter((session) => {
          if (session.targetDriverId && session.targetDriverId !== driverId) {
            return false;
          }
          return !session.offers.some((offer) => offer.driverId === driverId);
        })
      : includeTargeted
        ? sessions
        : sessions.filter((session) => !session.targetDriverId);

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
        offered_fare: session.offeredFareCentavos / 100,
        offered_fare_centavos: session.offeredFareCentavos,
        status: session.status,
        target_driver_id: session.targetDriverId,
        expires_at: session.expiresAt.toISOString(),
        created_at: session.createdAt.toISOString(),
      };
    });
  }

  async getOffers(
    sessionId: string,
    viewerId: string,
    viewerRole: string,
  ) {
    const session = await this.repository.findSessionWithOffers(sessionId);
    if (!session) throw new HTTPException(404, { message: 'BID_SESSION_NOT_FOUND' });
    if (viewerRole !== 'internal' && session.passengerId !== viewerId) {
      throw new HTTPException(403, { message: 'BID_SESSION_FORBIDDEN' });
    }
    return session.offers
      .filter((offer) => offer.status === 'pending')
      .map((offer) => this.formatOffer(offer));
  }

  private async validateDriverForOffer(
    session: BidSession,
    driverId: string,
    proposedFareCentavos: number,
  ) {
    if (session.targetDriverId && session.targetDriverId !== driverId) {
      throw new HTTPException(403, { message: 'SESSION_NOT_AVAILABLE_TO_DRIVER' });
    }
    const commissionBasisPoints = await this.adminClient.currentCommission();
    const requiredCommissionCentavos = Math.round(
      (proposedFareCentavos * commissionBasisPoints) / 10_000,
    );
    const [profile, eligibility, activeRides] = await Promise.all([
      this.driverClient.fetchProfile(driverId),
      this.driverClient.checkEligibility(driverId, requiredCommissionCentavos),
      this.tripClient.fetchDriverActiveRides(driverId),
    ]);
    if (!eligibility.eligible) {
      throw new HTTPException(409, {
        message: eligibility.code || 'DRIVER_NOT_ELIGIBLE',
      });
    }
    if (activeRides.length >= 5) {
      throw new HTTPException(409, { message: 'DRIVER_MAX_CAP_REACHED' });
    }
    if (activeRides.some((ride) => ride.ride_type === 'Bao Premium')) {
      throw new HTTPException(409, { message: 'DRIVER_HAS_ACTIVE_PRIORITY_RIDE' });
    }
    if (session.rideType === 'Bao Premium' && activeRides.length > 0) {
      throw new HTTPException(409, { message: 'PRIORITY_RIDE_REQUIRES_IDLE_DRIVER' });
    }
    return profile;
  }

  async placeOffer(
    sessionId: string,
    driverId: string,
    offerData: { proposed_fare?: number | null },
  ) {
    const session = await this.repository.findSessionById(sessionId);
    if (!session) throw new HTTPException(404, { message: 'BID_SESSION_NOT_FOUND' });
    if (session.status !== 'open') {
      throw new HTTPException(409, { message: `BID_SESSION_${session.status.toUpperCase()}` });
    }
    if (new Date() > session.expiresAt) {
      await this.repository.updateSessionStatus(sessionId, 'canceled');
      throw new HTTPException(409, { message: 'BID_SESSION_EXPIRED' });
    }
    if (await this.repository.findPendingOffer(sessionId, driverId)) {
      throw new HTTPException(409, { message: 'OFFER_ALREADY_PLACED' });
    }

    const proposedFareCentavos = offerData.proposed_fare == null
      ? session.offeredFareCentavos
      : Math.round(offerData.proposed_fare * 100);
    try {
      const profile = await this.validateDriverForOffer(
        session,
        driverId,
        proposedFareCentavos,
      );
      const offer = await this.repository.createOffer(sessionId, {
        driverId,
        driverName: profile.name,
        plateNumber: profile.plateNumber ?? 'Unknown',
        vehicleType: profile.vehicleType ?? 'BaoBao',
        proposedFare: proposedFareCentavos / 100,
        proposedFareCentavos,
      });
      return this.formatOffer(offer);
    } catch (error) {
      this.throwPublicError(error);
    }
  }

  private async completedAssignment(session: BidSession) {
    const details = await this.repository.findSessionWithOffers(session.id);
    const offer = details?.offers.find((candidate) => (
      candidate.id === session.acceptedOfferId
    ));
    if (!offer || !session.acceptedTripId) {
      throw new HTTPException(503, { message: 'ASSIGNMENT_RECOVERY_REQUIRED' });
    }
    return this.formatAssignment(session, offer);
  }

  /**
   * Claims the session before remote writes, reserves commission through trip-service,
   * and only then commits the accepted bid. Any completed remote step is compensated.
   */
  private async assignOffer(input: {
    session: BidSession;
    offer: DriverOffer;
    idempotencyKey: string;
    assignmentSource: 'driver_offer' | 'admin';
    assignedByAdminId?: string | null;
    rejectOfferOnRollback?: boolean;
  }) {
    const claim = await this.repository.claimAssignment({
      sessionId: input.session.id,
      offerId: input.offer.id,
      driverId: input.offer.driverId,
      idempotencyKey: input.idempotencyKey,
      assignmentSource: input.assignmentSource,
      assignedByAdminId: input.assignedByAdminId,
    });
    if (!claim.session) {
      throw new HTTPException(404, { message: 'BID_SESSION_NOT_FOUND' });
    }
    if (claim.state === 'conflict') {
      throw new HTTPException(409, { message: 'BID_SESSION_ASSIGNMENT_CONFLICT' });
    }
    if (claim.state === 'completed') {
      return await this.completedAssignment(claim.session);
    }

    let tripId = claim.session.acceptedTripId;
    try {
      if (!tripId) {
        const trip = await this.tripClient.createRide({
          passenger_id: input.session.passengerId,
          ride_type: input.session.rideType,
          pickup_latitude: input.session.pickupLatitude,
          pickup_longitude: input.session.pickupLongitude,
          pickup_name: input.session.pickupName,
          dropoff_latitude: input.session.dropoffLatitude,
          dropoff_longitude: input.session.dropoffLongitude,
          dropoff_name: input.session.dropoffName,
          fare: input.offer.proposedFareCentavos / 100,
          assignment_source: input.assignmentSource,
          assigned_by_admin_id: input.assignedByAdminId ?? null,
        }, `${input.idempotencyKey}:create`);
        tripId = trip.id;
        await this.repository.recordAssignmentTrip(
          input.session.id,
          input.idempotencyKey,
          tripId,
        );
      }

      await this.tripClient.acceptRide(tripId, {
        driverId: input.offer.driverId,
        assignmentSource: input.assignmentSource,
        assignedByAdminId: input.assignedByAdminId,
        idempotencyKey: `${input.idempotencyKey}:accept`,
      });
      const result = await this.repository.completeAssignment(
        input.session.id,
        input.offer.id,
        input.idempotencyKey,
        tripId,
      );
      return this.formatAssignment(result.session, result.offer);
    } catch (error) {
      const current = await this.repository.findSessionById(input.session.id)
        .catch(() => null);
      if (
        current?.status === 'accepted'
        && current.acceptanceIdempotencyKey === input.idempotencyKey
        && current.acceptedOfferId === input.offer.id
        && current.acceptedTripId === tripId
      ) {
        return await this.completedAssignment(current);
      }
      if (tripId) {
        try {
          await this.tripClient.cancelRide(
            tripId,
            `${input.idempotencyKey}:rollback`,
          );
        } catch (rollbackError) {
          Logger.error(
            `Assignment ${input.idempotencyKey} requires recovery for trip ${tripId}:`,
            rollbackError,
          );
          throw new HTTPException(503, { message: 'ASSIGNMENT_RECOVERY_REQUIRED' });
        }
      }
      try {
        await this.repository.releaseAssignment(
          input.session.id,
          input.idempotencyKey,
          input.rejectOfferOnRollback ? input.offer.id : undefined,
        );
      } catch (rollbackError) {
        Logger.error(
          `Assignment ${input.idempotencyKey} could not release its local claim:`,
          rollbackError,
        );
        throw new HTTPException(503, { message: 'ASSIGNMENT_RECOVERY_REQUIRED' });
      }
      this.throwPublicError(error);
    }
  }

  async acceptOffer(
    sessionId: string,
    offerId: string,
    passengerId: string,
  ) {
    const session = await this.repository.findSessionWithOffers(sessionId);
    if (!session) throw new HTTPException(404, { message: 'BID_SESSION_NOT_FOUND' });
    if (session.passengerId !== passengerId) {
      throw new HTTPException(403, { message: 'BID_SESSION_FORBIDDEN' });
    }
    const idempotencyKey = `passenger:${sessionId}:offer:${offerId}`;
    if (
      session.status === 'accepted'
      && session.acceptanceIdempotencyKey === idempotencyKey
    ) {
      return await this.completedAssignment(session);
    }
    if (session.status !== 'open' && session.status !== 'assigning') {
      throw new HTTPException(409, {
        message: `BID_SESSION_${session.status.toUpperCase()}`,
      });
    }
    if (session.status === 'open' && new Date() > session.expiresAt) {
      await this.repository.updateSessionStatus(sessionId, 'canceled');
      throw new HTTPException(409, { message: 'BID_SESSION_EXPIRED' });
    }
    const offer = session.offers.find((candidate) => (
      candidate.id === offerId
      && (
        candidate.status === 'pending'
        || candidate.id === session.acceptedOfferId
      )
    ));
    if (!offer) {
      throw new HTTPException(404, { message: 'OFFER_NOT_FOUND' });
    }
    return await this.assignOffer({
      session,
      offer,
      idempotencyKey,
      assignmentSource: 'driver_offer',
    });
  }

  async manualAssign(
    sessionId: string,
    driverId: string,
    adminId: string,
    idempotencyKey: string,
  ) {
    const session = await this.repository.findSessionWithOffers(sessionId);
    if (!session) throw new HTTPException(404, { message: 'BID_SESSION_NOT_FOUND' });
    if (
      session.acceptedDriverId === driverId
      && session.assignmentSource === 'admin'
      && session.assignedByAdminId === adminId
      && session.acceptedOfferId
      && session.acceptanceIdempotencyKey
    ) {
      const existingOffer = session.offers.find((offer) => (
        offer.id === session.acceptedOfferId
      ));
      if (!existingOffer) {
        throw new HTTPException(503, { message: 'ASSIGNMENT_RECOVERY_REQUIRED' });
      }
      return await this.assignOffer({
        session,
        offer: existingOffer,
        idempotencyKey: session.acceptanceIdempotencyKey,
        assignmentSource: 'admin',
        assignedByAdminId: adminId,
        rejectOfferOnRollback: true,
      });
    }
    if (session.status !== 'open') {
      throw new HTTPException(409, {
        message: `BID_SESSION_${session.status.toUpperCase()}`,
      });
    }
    if (new Date() > session.expiresAt) {
      await this.repository.updateSessionStatus(sessionId, 'canceled');
      throw new HTTPException(409, { message: 'BID_SESSION_EXPIRED' });
    }

    let offer: DriverOffer | undefined;
    try {
      const profile = await this.validateDriverForOffer(
        session,
        driverId,
        session.offeredFareCentavos,
      );
      offer = await this.repository.createOffer(sessionId, {
        driverId,
        driverName: profile.name,
        plateNumber: profile.plateNumber ?? 'Unknown',
        vehicleType: profile.vehicleType ?? 'BaoBao',
        proposedFare: session.offeredFareCentavos / 100,
        proposedFareCentavos: session.offeredFareCentavos,
      });
      return await this.assignOffer({
        session,
        offer,
        idempotencyKey,
        assignmentSource: 'admin',
        assignedByAdminId: adminId,
        rejectOfferOnRollback: true,
      });
    } catch (error) {
      if (offer) {
        const current = await this.repository.findSessionById(sessionId).catch(() => null);
        if (current?.acceptedOfferId !== offer.id) {
          await this.repository.updateOfferStatus(offer.id, 'rejected').catch(() => undefined);
        }
      }
      this.throwPublicError(error);
    }
  }

  async cancelSession(sessionId: string, passengerId: string) {
    const session = await this.repository.findSessionById(sessionId);
    if (!session) throw new HTTPException(404, { message: 'BID_SESSION_NOT_FOUND' });
    if (session.passengerId !== passengerId) {
      throw new HTTPException(403, { message: 'BID_SESSION_FORBIDDEN' });
    }
    if (session.status === 'accepted' || session.status === 'assigning') {
      throw new HTTPException(409, { message: 'BID_SESSION_CANNOT_BE_CANCELED' });
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
      throw new HTTPException(404, { message: 'PENDING_OFFER_NOT_FOUND' });
    }
    const updated = await this.repository.updateOfferStatus(pendingOffer.id, 'rejected');
    return {
      id: updated.id,
      session_id: updated.sessionId,
      driver_id: updated.driverId,
      status: updated.status,
    };
  }

  async getSessionDetails(
    sessionId: string,
    viewerId: string,
    viewerRole: string,
  ) {
    const session = await this.repository.findSessionWithOffers(sessionId);
    if (!session) throw new HTTPException(404, { message: 'BID_SESSION_NOT_FOUND' });
    const driverCanRead = (
      viewerRole === 'driver'
      && (!session.targetDriverId || session.targetDriverId === viewerId)
    );
    if (
      viewerRole !== 'internal'
      && session.passengerId !== viewerId
      && !driverCanRead
    ) {
      throw new HTTPException(403, { message: 'BID_SESSION_FORBIDDEN' });
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
      offered_fare: session.offeredFareCentavos / 100,
      offered_fare_centavos: session.offeredFareCentavos,
      status: session.status,
      target_driver_id: session.targetDriverId,
      accepted_driver_id: session.acceptedDriverId,
      accepted_trip_id: session.acceptedTripId,
      assignment_source: session.assignmentSource,
      assigned_by_admin_id: session.assignedByAdminId,
      expires_at: session.expiresAt.toISOString(),
      created_at: session.createdAt.toISOString(),
      offers: viewerRole === 'driver'
        ? session.offers
          .filter((offer) => offer.driverId === viewerId)
          .map((offer) => this.formatOffer(offer))
        : session.offers.map((offer) => this.formatOffer(offer)),
    };
  }
}

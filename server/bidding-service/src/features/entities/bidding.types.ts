export interface BidSession {
  id: string;
  passengerId: string;
  rideType: string;
  pickupLatitude: number;
  pickupLongitude: number;
  pickupName: string;
  dropoffLatitude: number;
  dropoffLongitude: number;
  dropoffName: string;
  distanceKm: number;
  durationMinutes: number;
  offeredFare: number;
  offeredFareCentavos: number;
  status: string;
  acceptedDriverId: string | null;
  acceptedOfferId: string | null;
  acceptedTripId: string | null;
  acceptanceIdempotencyKey: string | null;
  assignmentSource: string | null;
  assignedByAdminId: string | null;
  targetDriverId: string | null;
  createdAt: Date;
  updatedAt: Date;
  expiresAt: Date;
}

export interface DriverOffer {
  id: string;
  sessionId: string;
  driverId: string;
  driverName: string;
  plateNumber: string;
  vehicleType: string;
  proposedFare: number;
  proposedFareCentavos: number;
  status: string;
  createdAt: Date;
}

export interface BiddingRepository {
  createSession(details: any): Promise<BidSession>;
  findSessionById(id: string): Promise<BidSession | null>;
  findSessionWithOffers(id: string): Promise<BidSession & { offers: DriverOffer[] } | null>;
  findActiveSessions(now: Date): Promise<(BidSession & { offers: DriverOffer[] })[]>;
  expireSessions(now: Date): Promise<void>;
  findPendingOffer(sessionId: string, driverId: string): Promise<DriverOffer | null>;
  findOffersBySessionId(sessionId: string): Promise<DriverOffer[]>;
  createOffer(sessionId: string, offerDetails: any): Promise<DriverOffer>;
  claimAssignment(input: {
    sessionId: string;
    offerId: string;
    driverId: string;
    idempotencyKey: string;
    assignmentSource: 'driver_offer' | 'admin';
    assignedByAdminId?: string | null;
  }): Promise<{
    state: 'claimed' | 'retry' | 'completed' | 'conflict';
    session: BidSession | null;
  }>;
  recordAssignmentTrip(
    sessionId: string,
    idempotencyKey: string,
    tripId: string,
  ): Promise<BidSession>;
  completeAssignment(
    sessionId: string,
    offerId: string,
    idempotencyKey: string,
    tripId: string,
  ): Promise<{ session: BidSession; offer: DriverOffer }>;
  releaseAssignment(
    sessionId: string,
    idempotencyKey: string,
    offerId?: string,
  ): Promise<void>;
  updateSessionStatus(id: string, status: string): Promise<BidSession>;
  updateOfferStatus(id: string, status: string): Promise<DriverOffer>;
}

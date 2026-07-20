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
  status: string;
  acceptedDriverId: string | null;
  targetDriverId: string | null;
  createdAt: Date;
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
  acceptOfferTransaction(sessionId: string, offerId: string, acceptedDriverId: string): Promise<{ session: BidSession; offer: DriverOffer }>;
  updateSessionStatus(id: string, status: string): Promise<BidSession>;
  updateOfferStatus(id: string, status: string): Promise<DriverOffer>;
}

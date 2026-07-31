export type RideType = 'solo-ride' | 'share-bao';

export interface Passenger {
  id: string;
  name: string;
  email: string;
  phone: string;
  preferred_ride_type: RideType | null;
  created_at: Date;
  password_hash: string;
  is_verified: boolean;
}

export type SafePassenger = Omit<Passenger, 'password_hash'>;

export interface RideRequest {
  id: string;
  passenger_id: string;
  ride_type: RideType;
  pickup_latitude: number;
  pickup_longitude: number;
  pickup_name: string;
  dropoff_latitude: number;
  dropoff_longitude: number;
  dropoff_name: string;
  fare: number;
  status: string;
  created_at: Date;
  driver_name?: string;
  plate_number?: string;
}

export interface UpdatePassengerOptions {
  id: string;
  name: string;
  phone: string;
  email: string;
}

export interface PassengerNotification {
  id: string;
  passengerId: string;
  title: string;
  message: string;
  createdAt: Date;
}

export interface PassengerRepository {
  retrievePassengerProfile(passengerId: string): Promise<Passenger | null>;
  retrievePassengerByEmail(passengerEmail: string): Promise<Passenger | null>;
  retrievePassengersByIds(passengerIds: string[]): Promise<Record<string, Passenger>>;
  registerRideRequest(rideDetails: any): Promise<RideRequest>;
  retrievePassengerRideHistory(passengerId: string): Promise<RideRequest[]>;
  updatePassengerProfile(options: UpdatePassengerOptions): Promise<Passenger>;
  retrievePassengerNotifications(passengerId: string): Promise<PassengerNotification[]>;
  findActiveRestriction(passengerId: string): Promise<{
    id: string;
    reason: string;
    endsAt: Date | null;
  } | null>;
  createRestriction(input: {
    passengerId: string;
    caseId?: string | null;
    reason: string;
    endsAt?: Date | null;
    createdBy: string;
    idempotencyKey: string;
  }): Promise<{
    id: string;
    passengerId: string;
    reason: string;
    endsAt: Date | null;
  }>;
  listRestrictions(passengerId: string): Promise<Array<{
    id: string;
    passengerId: string;
    reason: string;
    endsAt: Date | null;
    revokedAt: Date | null;
  }>>;
  revokeRestriction(restrictionId: string): Promise<{
    id: string;
    passengerId: string;
    reason: string;
    endsAt: Date | null;
    revokedAt: Date | null;
  } | null>;
}

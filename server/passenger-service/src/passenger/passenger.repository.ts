import { Passenger, RideRequest } from './types.ts';
import { CreatePassengerRequest, CreateRideRequest } from './schema.ts';

export interface UpdatePassengerOptions {
  id: string;
  name: string;
  phone: string;
  email: string;
}

export interface PassengerRepository {
  registerPassenger(passengerDetails: CreatePassengerRequest): Promise<Passenger>;
  retrievePassengerProfile(passengerId: string): Promise<Passenger | null>;
  retrievePassengerByEmail(passengerEmail: string): Promise<Passenger | null>;
  registerRideRequest(rideDetails: CreateRideRequest): Promise<RideRequest>;
  retrievePassengerRideHistory(passengerId: string): Promise<RideRequest[]>;
  updatePassengerProfile(options: UpdatePassengerOptions): Promise<Passenger>;
  retrievePassengerNotifications(passengerId: string): Promise<any[]>;
  verifyPassengerOtp(passengerEmail: string): Promise<void>;
}

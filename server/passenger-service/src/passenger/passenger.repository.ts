import { Passenger, RideRequest } from './types.ts';
import { CreatePassengerRequest, CreateRideRequest } from './schema.ts';

export interface UpdatePassengerOptions {
  id: string;
  name: string;
  phone: string;
  email: string;
}

export interface PassengerRepository {
  createPassenger(req: CreatePassengerRequest): Promise<Passenger>;
  getPassenger(id: string): Promise<Passenger | null>;
  getPassengerByEmail(email: string): Promise<Passenger | null>;
  createRideRequest(req: CreateRideRequest): Promise<RideRequest>;
  getPassengerRides(passengerId: string): Promise<RideRequest[]>;
  updatePassenger(options: UpdatePassengerOptions): Promise<Passenger>;
  getPassengerNotifications(passengerId: string): Promise<any[]>;
  verifyPassenger(email: string): Promise<void>;
}

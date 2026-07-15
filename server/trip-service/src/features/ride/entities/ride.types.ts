/**
 * TypeScript interface declarations representing ride database entities.
 */
export interface Ride {
  id: string;
  passengerId: string;
  passengerName: string | null;
  rideType: string;
  pickupLatitude: number;
  pickupLongitude: number;
  pickupName: string;
  dropoffLatitude: number;
  dropoffLongitude: number;
  dropoffName: string;
  fare: number;
  status: string;
  createdAt: Date;
  completedAt: Date | null;
  driverId: string | null;
  driverName: string | null;
  driverRating: string | null;
  vehicleType: string | null;
  plateNumber: string | null;
}

export interface RideRepository {
  createRide(details: any): Promise<Ride>;
  findRideById(id: string): Promise<Ride | null>;
  findActiveRides(): Promise<Ride[]>;
  findRidesByDriverId(driverId: string): Promise<Ride[]>;
  findRidesByPassengerId(passengerId: string): Promise<Ride[]>;
  acceptRideTransaction(id: string, driverData: any): Promise<Ride>;
  updateRideStatus(id: string, status: string, completedAt?: Date): Promise<Ride>;
}

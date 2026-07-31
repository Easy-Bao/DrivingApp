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
  fareCentavos: number | null;
  commissionRateBasisPoints: number | null;
  commissionCentavos: number | null;
  creditReservationId: string | null;
  assignmentSource: string;
  assignedByAdminId: string | null;
  paymentStatus: string;
  pendingStatus: string | null;
  statusRequestId: string | null;
  statusTransitionStartedAt: Date | null;
  status: string;
  createdAt: Date;
  updatedAt: Date;
  completedAt: Date | null;
  driverId: string | null;
  driverName: string | null;
  driverRating: string | null;
  vehicleType: string | null;
  plateNumber: string | null;
  creationRequestId: string | null;
  creationRequestHash: string | null;
}

export interface RideRepository {
  createRide(details: any): Promise<Ride>;
  findRideById(id: string): Promise<Ride | null>;
  findActiveRides(): Promise<Ride[]>;
  findRidesByDriverId(driverId: string): Promise<Ride[]>;
  findRidesByPassengerId(passengerId: string): Promise<Ride[]>;
  acceptRideTransaction(id: string, driverData: any): Promise<Ride>;
  beginStatusTransition(
    id: string,
    status: string,
    requestId: string,
  ): Promise<Ride>;
  completeStatusTransition(
    id: string,
    status: string,
    completedAt?: Date,
    paymentStatus?: string,
  ): Promise<Ride>;
  findPendingStatusTransitions(): Promise<Ride[]>;
  findRidesForReport(input: {
    status?: string;
    from?: Date;
    to?: Date;
  }): Promise<Ride[]>;
}

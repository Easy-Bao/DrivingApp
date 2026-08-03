export interface Coordinate {
  lat: number;
  lng: number;
  updatedAt: string;
}

export interface TelemetryRepository {
  updateLocation(driverId: string, lat: number, lng: number, updatedAt: string): void;
  getLocation(driverId: string): Coordinate | undefined;
  updatePassengerLocation(rideId: string, lat: number, lng: number, updatedAt: string): void;
  getPassengerLocation(rideId: string): Coordinate | undefined;
}

/**
 * TypeScript interface declarations representing telemetry coordinates.
 */
export interface Coordinate {
  lat: number;
  lng: number;
  updatedAt: string;
}

export interface TelemetryRepository {
  updateLocation(driverId: string, lat: number, lng: number, updatedAt: string): void;
  getLocation(driverId: string): Coordinate | undefined;
}

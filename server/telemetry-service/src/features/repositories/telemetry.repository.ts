import { Coordinate, TelemetryRepository } from '../entities/telemetry.types.ts';

export const locations = new Map<string, Coordinate>();

export class InMemoryTelemetryRepository implements TelemetryRepository {
  updateLocation(driverId: string, lat: number, lng: number, updatedAt: string): void {
    locations.set(driverId, { lat, lng, updatedAt });
  }

  getLocation(driverId: string): Coordinate | undefined {
    return locations.get(driverId);
  }
}

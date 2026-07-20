/**
 * Service layer orchestrating domain logic for telemetry GPS location tracking and spoofing detection.
 */
import { TelemetryRepository } from '../entities/telemetry.types.ts';
import { HTTPException } from 'hono/http-exception';
import { Logger } from '../../shared/logger/logger.ts';

function calculateDistanceKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
    Math.cos((lat2 * Math.PI) / 180) *
    Math.sin(dLon / 2) *
    Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

export class TelemetryService {
  private repository: TelemetryRepository;

  constructor(repository: TelemetryRepository) {
    this.repository = repository;
  }

  updateLocation(driverId: string, lat: number, lng: number) {
    const now = new Date();
    const prev = this.repository.getLocation(driverId);
    if (prev) {
      const prevTime = new Date(prev.updatedAt);
      const timeDiffSeconds = (now.getTime() - prevTime.getTime()) / 1000;
      if (timeDiffSeconds > 0) {
        const distance = calculateDistanceKm(prev.lat, prev.lng, lat, lng);
        const velocityKmh = (distance / timeDiffSeconds) * 3600;

        if (velocityKmh > 150) {
          Logger.warn(`GPS Spoofing detected for driver ${driverId}: speed of ${velocityKmh.toFixed(1)} km/h exceeds 150 km/h threshold.`);
          throw new HTTPException(400, { message: 'GPS_SPOOFING_DETECTED' });
        }
      }
    }

    this.repository.updateLocation(driverId, lat, lng, now.toISOString());
  }

  getLocation(driverId: string) {
    const loc = this.repository.getLocation(driverId);
    if (!loc) {
      throw new HTTPException(404, { message: 'No location telemetry found' });
    }
    return loc;
  }
}

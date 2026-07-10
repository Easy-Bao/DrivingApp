export interface Coordinate {
  lat: number;
  lng: number;
  updatedAt: string;
}

export const locations = new Map<string, Coordinate>();

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

export function updateLocation(driverId: string, lat: string | number, lng: string | number) {
  const parsedLat = typeof lat === 'string' ? parseFloat(lat) : lat;
  const parsedLng = typeof lng === 'string' ? parseFloat(lng) : lng;
  const now = new Date();

  const prev = locations.get(driverId);
  if (prev) {
    const prevTime = new Date(prev.updatedAt);
    const timeDiffSeconds = (now.getTime() - prevTime.getTime()) / 1000;
    if (timeDiffSeconds > 0) {
      const distance = calculateDistanceKm(prev.lat, prev.lng, parsedLat, parsedLng);
      const velocityKmh = (distance / timeDiffSeconds) * 3600;

      if (velocityKmh > 150) {
        console.warn(`GPS Spoofing detected for driver ${driverId}: speed of ${velocityKmh.toFixed(1)} km/h exceeds 150 km/h threshold.`);
        throw new Error("GPS_SPOOFING_DETECTED");
      }
    }
  }

  locations.set(driverId, {
    lat: parsedLat,
    lng: parsedLng,
    updatedAt: now.toISOString(),
  });
}

export function getLocation(driverId: string): Coordinate | undefined {
  return locations.get(driverId);
}


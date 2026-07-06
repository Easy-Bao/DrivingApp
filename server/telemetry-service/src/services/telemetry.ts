export interface Coordinate {
  lat: number;
  lng: number;
  updatedAt: string;
}

export const locations = new Map<string, Coordinate>();

export function updateLocation(driverId: string, lat: string | number, lng: string | number) {
  locations.set(driverId, {
    lat: typeof lat === 'string' ? parseFloat(lat) : lat,
    lng: typeof lng === 'string' ? parseFloat(lng) : lng,
    updatedAt: new Date().toISOString(),
  });
}

export function getLocation(driverId: string): Coordinate | undefined {
  return locations.get(driverId);
}

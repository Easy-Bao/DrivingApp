/**
 * TypeScript type and interface declarations representing driver and review database entities.
 */
export interface Driver {
  id: string;
  name: string;
  email: string;
  phone: string;
  vehicleType: string;
  plateNumber: string;
  passwordHash: string;
  rating: number;
  isOnline: boolean;
  lat: number;
  lng: number;
  createdAt: Date;
}

export interface Review {
  id: string;
  driverId: string;
  passengerName: string;
  rating: number;
  comment: string;
  createdAt: Date;
}

export interface DriverRepository {
  registerDriver(details: any): Promise<Driver>;
  findDriverByEmail(email: string): Promise<Driver | null>;
  findDriverById(id: string): Promise<Driver | null>;
  findOnlineDrivers(): Promise<Driver[]>;
  updateOnlineStatus(id: string, isOnline: boolean, lat?: number, lng?: number): Promise<Driver>;
  fetchDriverReviews(driverId: string): Promise<Review[]>;
  seedDriverReviews(driverId: string, defaultReviews: any[]): Promise<Review[]>;
}

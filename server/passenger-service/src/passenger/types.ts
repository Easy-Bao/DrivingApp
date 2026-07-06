export type RideType = 'solo-ride' | 'share-bao';

export interface Passenger {
  id: string;
  name: string;
  email: string;
  phone: string;
  preferred_ride_type: RideType | null;
  created_at: Date;
  password_hash: string;
  is_verified: boolean;
}

export interface RideRequest {
  id: string;
  passenger_id: string;
  ride_type: RideType;
  pickup_latitude: number;
  pickup_longitude: number;
  pickup_name: string;
  dropoff_latitude: number;
  dropoff_longitude: number;
  dropoff_name: string;
  fare: number;
  status: string;
  created_at: Date;
  password_hash: String;
}

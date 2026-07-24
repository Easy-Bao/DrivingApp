import { z } from 'zod';

export const CreateBidSessionSchema = z.object({
  passenger_id: z.string().min(1, 'Invalid passenger ID'),
  ride_type: z.string().min(1, 'Ride type is required'),
  pickup_latitude: z.union([z.number(), z.string()]).transform((val) => typeof val === 'string' ? parseFloat(val) : val),
  pickup_longitude: z.union([z.number(), z.string()]).transform((val) => typeof val === 'string' ? parseFloat(val) : val),
  pickup_name: z.string().optional().default('Pickup'),
  dropoff_latitude: z.union([z.number(), z.string()]).transform((val) => typeof val === 'string' ? parseFloat(val) : val),
  dropoff_longitude: z.union([z.number(), z.string()]).transform((val) => typeof val === 'string' ? parseFloat(val) : val),
  dropoff_name: z.string().optional().default('Dropoff'),
  distance_km: z.union([z.number(), z.string()]).transform((val) => typeof val === 'string' ? parseFloat(val) : val),
  duration_minutes: z.union([z.number(), z.string()]).transform((val) => typeof val === 'string' ? parseFloat(val) : val),
  target_driver_id: z.string().optional().nullable(),
});

export const PlaceOfferSchema = z.object({
  driver_id: z.string().min(1, 'driver_id is required'),
  driver_name: z.string().min(1, 'driver_name is required'),
  plate_number: z.string().min(1, 'plate_number is required'),
  vehicle_type: z.string().min(1, 'vehicle_type is required'),
  proposed_fare: z.union([z.number(), z.string()]).transform((val) => typeof val === 'string' ? parseFloat(val) : val).optional().nullable(),
});

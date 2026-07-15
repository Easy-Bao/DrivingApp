/**
 * Zod validation schemas governing request inputs for ride features.
 */
import { z } from 'zod';

export const CreateRideSchema = z.object({
  passenger_id: z.string().uuid('Invalid passenger ID'),
  ride_type: z.string().optional().default('solo-ride'),
  pickup_latitude: z.union([z.number(), z.string()]).transform((val) => typeof val === 'string' ? parseFloat(val) : val),
  pickup_longitude: z.union([z.number(), z.string()]).transform((val) => typeof val === 'string' ? parseFloat(val) : val),
  pickup_name: z.string().optional().default('Pickup Location'),
  dropoff_latitude: z.union([z.number(), z.string()]).transform((val) => typeof val === 'string' ? parseFloat(val) : val),
  dropoff_longitude: z.union([z.number(), z.string()]).transform((val) => typeof val === 'string' ? parseFloat(val) : val),
  dropoff_name: z.string().optional().default('Dropoff Location'),
  fare: z.union([z.number(), z.string()]).transform((val) => typeof val === 'string' ? parseFloat(val) : val),
});

export const AcceptRideSchema = z.object({
  driver_id: z.string().min(1, 'driver_id is required'),
  driver_name: z.string().min(1, 'driver_name is required'),
  driver_rating: z.string().optional().nullable(),
  vehicle_type: z.string().optional().nullable(),
  plate_number: z.string().optional().nullable(),
});

export const UpdateStatusSchema = z.object({
  status: z.string().min(1, 'status is required'),
});

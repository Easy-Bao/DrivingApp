/**
 * Passenger validation schemas: uses Zod to validate payload schemas for creating passengers, logging in, and requesting rides.
 */
import { z } from 'zod';

export const CreatePassengerSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
  phone: z.string().min(1),
  password: z.string().min(6),
  preferred_ride_type: z.enum(['solo-ride', 'share-bao']).nullable().optional(),
});

export const LoginSchema = z.object({
  email: z.string().email(),
  password: z.string(),
});

export const CreateRideSchema = z.object({
  passenger_id: z.string().uuid(),
  ride_type: z.enum(['solo-ride', 'share-bao']),
  pickup_latitude: z.number(),
  pickup_longitude: z.number(),
  pickup_name: z.string().min(1),
  dropoff_latitude: z.number(),
  dropoff_longitude: z.number(),
  dropoff_name: z.string().min(1),
  fare: z.number().nonnegative(),
});

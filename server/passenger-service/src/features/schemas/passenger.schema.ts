import { z } from 'zod';
import { HTTPException } from 'hono/http-exception';

export const AdminActorHeaderSchema = z.string().trim().min(1).max(128);

export function requireAdminActorHeader(value: string | undefined): string {
  const actor = AdminActorHeaderSchema.safeParse(value);
  if (!actor.success) {
    throw new HTTPException(422, { message: 'INVALID_ADMIN_ACTOR' });
  }
  return actor.data;
}

export const CreatePassengerSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  email: z.string().email('Invalid email address'),
  phone: z.string().min(1, 'Phone number is required'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  preferred_ride_type: z.enum(['solo-ride', 'share-bao']).nullable().optional(),
});
export type CreatePassengerRequest = z.infer<typeof CreatePassengerSchema>;

export const LoginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(1, 'Password is required'),
});
export type LoginRequest = z.infer<typeof LoginSchema>;

export const CreateRideSchema = z.object({
  passenger_id: z.string().min(1, 'Invalid passenger ID'),
  ride_type: z.enum(['solo-ride', 'share-bao']),
  pickup_latitude: z.number(),
  pickup_longitude: z.number(),
  pickup_name: z.string().min(1, 'Pickup name is required'),
  dropoff_latitude: z.number(),
  dropoff_longitude: z.number(),
  dropoff_name: z.string().min(1, 'Dropoff name is required'),
  fare: z.number().nonnegative('Fare must be non-negative'),
});
export type CreateRideRequest = z.infer<typeof CreateRideSchema>;

export const UpdatePassengerSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  phone: z.string().min(1, 'Phone is required'),
  email: z.string().email('Invalid email address'),
});

export const RestrictPassengerSchema = z.object({
  case_id: z.string().nullable().optional(),
  ends_at: z.string().datetime().nullable().optional(),
  reason: z.string().min(3).max(1000),
});

export const LiftPassengerRestrictionSchema = z.object({
  reason: z.string().min(3).max(1000),
});

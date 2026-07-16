import { z } from 'zod';

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
  passenger_id: z.string().uuid('Invalid passenger ID'),
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

export const RegisterEmailSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
});
export type RegisterEmailRequest = z.infer<typeof RegisterEmailSchema>;

export const VerifyEmailOtpSchema = z.object({
  email: z.string().email('Invalid email address'),
  code: z.string().min(4).max(6),
});
export type VerifyEmailOtpRequest = z.infer<typeof VerifyEmailOtpSchema>;

export const CompleteProfileSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  phone: z.string().min(1, 'Phone number is required'),
});
export type CompleteProfileRequest = z.infer<typeof CompleteProfileSchema>;

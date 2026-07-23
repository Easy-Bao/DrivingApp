import { z } from 'zod';

export const RegisterPassengerSchema = z.object({
  name: z.string().min(2, 'Name is required'),
  email: z.string().email('Invalid email address'),
  phone: z.string().min(8, 'Valid phone number is required'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  preferred_ride_type: z.string().min(1, 'Preferred ride type is required'),
});

export const LoginPassengerSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(1, 'Password is required'),
});

export type RegisterPassengerInput = z.infer<typeof RegisterPassengerSchema>;
export type LoginPassengerInput = z.infer<typeof LoginPassengerSchema>;

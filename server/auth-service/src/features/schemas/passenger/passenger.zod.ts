import { z } from 'zod';

export const RegisterPassengerSchema = z.object({
  name: z.string().optional().default('Passenger'),
  email: z.string().email('Invalid email address'),
  phone: z.string().optional().default(''),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  preferred_ride_type: z.string().optional().default('standard'),
});

export const LoginPassengerSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(1, 'Password is required'),
});

export type RegisterPassengerInput = z.infer<typeof RegisterPassengerSchema>;
export type LoginPassengerInput = z.infer<typeof LoginPassengerSchema>;

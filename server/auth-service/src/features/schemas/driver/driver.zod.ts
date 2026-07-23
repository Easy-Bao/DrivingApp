import { z } from 'zod';

export const RegisterDriverSchema = z.object({
  name: z.string().min(2, 'Name is required'),
  email: z.string().email('Invalid email address'),
  phone: z.string().min(8, 'Valid phone number is required'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  vehicleType: z.string().min(1, 'Vehicle type is required'),
  plateNumber: z.string().min(1, 'Plate number is required'),
});

export const LoginDriverSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(1, 'Password is required'),
});

export type RegisterDriverInput = z.infer<typeof RegisterDriverSchema>;
export type LoginDriverInput = z.infer<typeof LoginDriverSchema>;

import { z } from 'zod';

export const RegisterDriverSchema = z.object({
  name: z.string().optional().default('Driver'),
  email: z.string().email('Invalid email address'),
  phone: z.string().optional().default(''),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  vehicleType: z.string().optional().default('sedan'),
  plateNumber: z.string().optional().default('N/A'),
});

export const LoginDriverSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(1, 'Password is required'),
});

export type RegisterDriverInput = z.infer<typeof RegisterDriverSchema>;
export type LoginDriverInput = z.infer<typeof LoginDriverSchema>;

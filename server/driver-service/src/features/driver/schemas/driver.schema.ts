/**
 * Zod validation schemas governing request inputs for driver features.
 */
import { z } from 'zod';

export const CreateDriverSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  email: z.string().email('Invalid email address'),
  phone: z.string().min(1, 'Phone is required'),
  vehicleType: z.string().min(1, 'Vehicle type is required'),
  plateNumber: z.string().min(1, 'Plate number is required'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
});
export type CreateDriverRequest = z.infer<typeof CreateDriverSchema>;

export const LoginDriverSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(1, 'Password is required'),
});
export type LoginDriverRequest = z.infer<typeof LoginDriverSchema>;

export const UpdateOnlineStatusSchema = z.object({
  isOnline: z.boolean(),
  lat: z.number().optional().nullable(),
  lng: z.number().optional().nullable(),
});
export type UpdateOnlineStatusRequest = z.infer<typeof UpdateOnlineStatusSchema>;

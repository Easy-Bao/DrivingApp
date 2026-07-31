import { z } from 'zod';

export const LoginAdminSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(1, 'Password is required'),
});

export const ProvisionAdminSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string()
    .min(12, 'Password must be at least 12 characters')
    .max(128, 'Password must be at most 128 characters'),
});

export type LoginAdminInput = z.infer<typeof LoginAdminSchema>;

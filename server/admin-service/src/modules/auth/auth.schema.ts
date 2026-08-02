import { z } from 'zod';

export const AdminLoginSchema = z.object({
  email: z.string().trim().toLowerCase().email(),
  password: z.string().min(12).max(128),
});

export const OwnerInputSchema = AdminLoginSchema;

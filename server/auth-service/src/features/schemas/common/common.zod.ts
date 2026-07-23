import { z } from 'zod';

export const VerifyOtpSchema = z.object({
  email: z.string().email('Invalid email address'),
  code: z.string().length(6, 'OTP code must be 6 digits'),
});

export const ForgotPasswordSchema = z.object({
  email: z.string().email('Invalid email address'),
});

export const ResetPasswordSchema = z.object({
  email: z.string().email('Invalid email address'),
  code: z.string().length(6, 'OTP code must be 6 digits'),
  newPassword: z.string().min(8, 'Password must be at least 8 characters'),
});

export const VerifyTokenSchema = z.object({
  token: z.string().min(1, 'Token is required'),
});

export const AuthUserResponseSchema = z.object({
  id: z.string(),
  email: z.string(),
  name: z.string(),
  phone: z.string(),
  role: z.enum(['passenger', 'driver']),
  isVerified: z.boolean(),
  createdAt: z.date().or(z.string()),
  vehicleType: z.string().optional(),
  plateNumber: z.string().optional(),
  rating: z.number().optional(),
  preferred_ride_type: z.string().optional(),
});

export type VerifyOtpInput = z.infer<typeof VerifyOtpSchema>;
export type ForgotPasswordInput = z.infer<typeof ForgotPasswordSchema>;
export type ResetPasswordInput = z.infer<typeof ResetPasswordSchema>;
export type VerifyTokenInput = z.infer<typeof VerifyTokenSchema>;
export type AuthUserResponse = z.infer<typeof AuthUserResponseSchema>;

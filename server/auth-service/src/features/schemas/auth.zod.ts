import { z } from 'zod';

export const RegisterPassengerSchema = z.object({
  name: z.string().min(2, 'Name is required'),
  email: z.string().email('Invalid email address'),
  phone: z.string().min(8, 'Valid phone number is required'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  preferred_ride_type: z.string().optional(),
});

export const RegisterDriverSchema = z.object({
  name: z.string().min(2, 'Name is required'),
  email: z.string().email('Invalid email address'),
  phone: z.string().min(8, 'Valid phone number is required'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  vehicleType: z.string().optional(),
  plateNumber: z.string().optional(),
});

export const LoginAuthSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(1, 'Password is required'),
});

export const VerifyOtpAuthSchema = z.object({
  email: z.string().email('Invalid email address'),
  code: z.string().length(6, 'OTP code must be 6 digits'),
});

export const ForgotPasswordAuthSchema = z.object({
  email: z.string().email('Invalid email address'),
});

export const ResetPasswordAuthSchema = z.object({
  email: z.string().email('Invalid email address'),
  code: z.string().length(6, 'OTP code must be 6 digits'),
  newPassword: z.string().min(6, 'New password must be at least 6 characters'),
});

export const VerifyTokenAuthSchema = z.object({
  token: z.string().min(1, 'Token is required'),
});

// Sanitized public DTO schema — explicitly excludes password_hash and internal credentials
export const AuthUserResponseSchema = z.object({
  id: z.string(),
  email: z.string(),
  name: z.string().optional(),
  phone: z.string().optional(),
  role: z.enum(['passenger', 'driver']),
  isVerified: z.boolean(),
  createdAt: z.date().or(z.string()),
  vehicleType: z.string().optional(),
  plateNumber: z.string().optional(),
  rating: z.number().optional(),
  preferred_ride_type: z.string().optional(),
});

export type RegisterPassengerInput = z.infer<typeof RegisterPassengerSchema>;
export type RegisterDriverInput = z.infer<typeof RegisterDriverSchema>;
export type LoginAuthInput = z.infer<typeof LoginAuthSchema>;
export type VerifyOtpAuthInput = z.infer<typeof VerifyOtpAuthSchema>;
export type ForgotPasswordAuthInput = z.infer<typeof ForgotPasswordAuthSchema>;
export type ResetPasswordAuthInput = z.infer<typeof ResetPasswordAuthSchema>;
export type VerifyTokenAuthInput = z.infer<typeof VerifyTokenAuthSchema>;
export type AuthUserResponse = z.infer<typeof AuthUserResponseSchema>;

import { z } from 'zod';

export const EstimateFareSchema = z.object({
  distanceKm: z.number().min(0, 'Distance must be non-negative'),
  durationMinutes: z.number().min(0, 'Duration must be non-negative').default(0.0),
  rideType: z.string().optional(),
});

export type EstimateFareRequest = z.infer<typeof EstimateFareSchema>;

export const CalculateFinalFareSchema = z.object({
  rideId: z.string().min(1, 'Ride ID is required'),
  distanceKm: z.number().min(0, 'Distance must be non-negative'),
  durationMinutes: z.number().min(0, 'Duration must be non-negative'),
  rideType: z.string().default('Solo Ride'),
  surgeMultiplier: z.number().min(1.0).optional().default(1.0),
  driverId: z.string().min(1).optional(),
});

export type CalculateFinalFareRequest = z.infer<typeof CalculateFinalFareSchema>;

export const UpdatePricingSchema = z.object({
  base_fare: z.number().min(0),
  per_km_rate: z.number().min(0),
  per_minute_rate: z.number().min(0),
  minimum_fare: z.number().min(0),
  surge_multiplier: z.number().min(1).max(3),
  is_active: z.boolean(),
  reason: z.string().min(3).max(1000),
  admin_id: z.string().min(1),
});

export const RecordFareSnapshotSchema = z.object({
  rideId: z.string().min(1),
  driverId: z.string().min(1),
  serviceType: z.string().min(1),
  totalFareCentavos: z.number().int().nonnegative(),
  commissionRateBasisPoints: z.number().int().min(0).max(10_000),
  commissionCentavos: z.number().int().nonnegative(),
  assignmentSource: z.enum(['driver_offer', 'admin']),
});

export const UpdateFarePaymentStatusSchema = z.object({
  paymentStatus: z.enum([
    'cash_pending',
    'cash_received',
    'cash_disputed',
    'canceled',
  ]),
});

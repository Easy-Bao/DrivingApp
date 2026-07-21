import { z } from 'zod';

export const EstimateFareV2Schema = z.object({
  distanceKm: z.number().min(0, 'Distance must be non-negative'),
  durationMinutes: z.number().min(0, 'Duration must be non-negative').default(0.0),
  passengerCount: z.number().int().min(1).max(6).optional().default(1),
  promoCode: z.string().optional(),
});

export type EstimateFareV2Request = z.infer<typeof EstimateFareV2Schema>;

export const CalculateFinalFareV2Schema = z.object({
  rideId: z.string().min(1, 'Ride ID is required'),
  distanceKm: z.number().min(0, 'Distance must be non-negative'),
  durationMinutes: z.number().min(0, 'Duration must be non-negative'),
  rideType: z.string().default('Solo Ride'),
  surgeMultiplier: z.number().min(1.0).optional().default(1.0),
});

export type CalculateFinalFareV2Request = z.infer<typeof CalculateFinalFareV2Schema>;

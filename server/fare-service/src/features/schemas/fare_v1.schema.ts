import { z } from 'zod';

export const EstimateFareV1Schema = z.object({
  distanceKm: z.number().min(0, 'Distance must be non-negative'),
  durationMinutes: z.number().min(0, 'Duration must be non-negative').default(0.0),
  rideType: z.string().optional().default('Solo Ride'),
});

export type EstimateFareV1Request = z.infer<typeof EstimateFareV1Schema>;

export const CalculateFinalFareV1Schema = z.object({
  rideId: z.string().min(1, 'Ride ID is required'),
  distanceKm: z.number().min(0, 'Distance must be non-negative'),
  durationMinutes: z.number().min(0, 'Duration must be non-negative'),
  rideType: z.string().default('Solo Ride'),
});

export type CalculateFinalFareV1Request = z.infer<typeof CalculateFinalFareV1Schema>;

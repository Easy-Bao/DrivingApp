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
});

export type CalculateFinalFareRequest = z.infer<typeof CalculateFinalFareSchema>;

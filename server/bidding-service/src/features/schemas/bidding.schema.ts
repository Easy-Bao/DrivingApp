import { z } from 'zod';

const LatitudeSchema = z.coerce.number().finite().min(-90).max(90);
const LongitudeSchema = z.coerce.number().finite().min(-180).max(180);
const NonNegativeNumberSchema = z.coerce.number().finite().nonnegative();

export const EstimateFareSchema = z.object({
  ride_type: z.string().trim().min(1).max(80).default('Solo Ride'),
  distance_km: NonNegativeNumberSchema,
  duration_minutes: NonNegativeNumberSchema,
});

export const CreateBidSessionSchema = z.object({
  ride_type: z.string().trim().min(1, 'Ride type is required').max(80),
  pickup_latitude: LatitudeSchema,
  pickup_longitude: LongitudeSchema,
  pickup_name: z.string().trim().min(1).max(240).optional().default('Pickup'),
  dropoff_latitude: LatitudeSchema,
  dropoff_longitude: LongitudeSchema,
  dropoff_name: z.string().trim().min(1).max(240).optional().default('Dropoff'),
  distance_km: NonNegativeNumberSchema,
  duration_minutes: NonNegativeNumberSchema,
  target_driver_id: z.string().trim().min(1).max(128).optional().nullable(),
});

export const PlaceOfferSchema = z.object({
  proposed_fare: NonNegativeNumberSchema.positive().max(1_000_000).optional().nullable(),
});

export const AcceptOfferSchema = z.object({
  offer_id: z.string().trim().min(1).max(128),
});

export const ManualAssignmentSchema = z.object({
  driver_id: z.string().trim().min(1).max(128),
  admin_id: z.string().trim().min(1).max(128),
  reason: z.string().trim().min(3).max(1_000),
});

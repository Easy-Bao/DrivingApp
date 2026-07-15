/**
 * Zod validation schemas governing request inputs for telemetry updates.
 */
import { z } from 'zod';

export const LocationUpdateSchema = z.object({
  driverId: z.string().min(1, 'driverId is required'),
  lat: z.union([z.number(), z.string()]).transform((val) => typeof val === 'string' ? parseFloat(val) : val),
  lng: z.union([z.number(), z.string()]).transform((val) => typeof val === 'string' ? parseFloat(val) : val),
});

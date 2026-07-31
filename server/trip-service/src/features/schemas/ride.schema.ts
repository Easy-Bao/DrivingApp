import { z } from 'zod';

const RideDetailsSchema = z.object({
  ride_type: z.string().optional().default('solo-ride'),
  pickup_latitude: z.union([z.number(), z.string()]).transform((val) => typeof val === 'string' ? parseFloat(val) : val),
  pickup_longitude: z.union([z.number(), z.string()]).transform((val) => typeof val === 'string' ? parseFloat(val) : val),
  pickup_name: z.string().optional().default('Pickup Location'),
  dropoff_latitude: z.union([z.number(), z.string()]).transform((val) => typeof val === 'string' ? parseFloat(val) : val),
  dropoff_longitude: z.union([z.number(), z.string()]).transform((val) => typeof val === 'string' ? parseFloat(val) : val),
  dropoff_name: z.string().optional().default('Dropoff Location'),
  fare: z.union([z.number(), z.string()]).transform((val) => typeof val === 'string' ? parseFloat(val) : val),
});

export const CreateRideSchema = RideDetailsSchema;

export const InternalCreateRideSchema = RideDetailsSchema.extend({
  passenger_id: z.string().min(1, 'Invalid passenger ID'),
  assignment_source: z.enum(['driver_offer', 'admin']).optional(),
  assigned_by_admin_id: z.string().optional().nullable(),
});

export const AcceptRideSchema = z.object({
  driver_id: z.string().min(1, 'driver_id is required'),
  assignment_source: z.enum(['driver_offer', 'admin']).optional(),
  assigned_by_admin_id: z.string().optional().nullable(),
});

export const UpdateStatusSchema = z.object({
  status: z.enum([
    'arrived',
    'in_transit',
    'completed',
    'canceled',
    'cancelled',
    'payment_disputed',
  ]),
});

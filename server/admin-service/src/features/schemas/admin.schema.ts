import { z } from 'zod';

const FilterDateSchema = z.string().refine(
  (value) => Number.isFinite(new Date(value).getTime()),
  'Invalid date filter',
);

const ListQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(25),
  from: FilterDateSchema.optional(),
  to: FilterDateSchema.optional(),
});

export const CaseListQuerySchema = ListQuerySchema.extend({
  status: z.enum(['open', 'under_review', 'resolved', 'dismissed']).optional(),
}).refine((value) => (
  !value.from || !value.to || new Date(value.from) <= new Date(value.to)
), {
  message: 'from must not be after to',
});

export const AuditListQuerySchema = ListQuerySchema.extend({
  status: z.enum(['succeeded', 'failed']).optional(),
}).refine((value) => (
  !value.from || !value.to || new Date(value.from) <= new Date(value.to)
), {
  message: 'from must not be after to',
});

export const ApprovalSchema = z.object({
  status: z.enum(['pending', 'approved', 'rejected']),
  reason: z.string().min(3).max(1000),
});

export const DocumentRequirementSchema = z.object({
  name: z.string().min(2).max(120),
  requires_expiry: z.boolean().default(false),
  is_active: z.boolean().default(true),
  reason: z.string().min(3).max(1000),
});

export const DocumentRequirementUpdateSchema = z.object({
  name: z.string().min(2).max(120).optional(),
  requires_expiry: z.boolean().optional(),
  is_active: z.boolean().optional(),
  reason: z.string().min(3).max(1000),
}).refine((value) => (
  value.name !== undefined
  || value.requires_expiry !== undefined
  || value.is_active !== undefined
), {
  message: 'At least one requirement field must be supplied',
});

export const DocumentReviewSchema = z.object({
  status: z.enum(['pending', 'verified', 'rejected', 'expired']),
  expires_at: z.string().datetime().nullable().optional(),
  notes: z.string().max(1000).nullable().optional(),
  reason: z.string().min(3).max(1000),
});

export const TopUpReviewSchema = z.object({
  status: z.enum(['approved', 'rejected']),
  reason: z.string().min(3).max(1000),
});

export const CreditAdjustmentSchema = z.object({
  amount_centavos: z.number().int().min(-100_000).max(100_000)
    .refine((amount) => amount !== 0, 'Adjustment cannot be zero'),
  reason: z.string().min(3).max(1000),
});

export const CreditRefundSchema = z.object({
  amount_centavos: z.number().int().positive().max(100_000),
  reason: z.string().min(3).max(1000),
});

export const TopUpChannelCreateSchema = z.object({
  name: z.string().min(2).max(80),
  account_name: z.string().min(2).max(120),
  account_reference: z.string().min(3).max(120),
  instructions: z.string().max(1000).nullable().optional(),
  reason: z.string().min(3).max(1000),
});

export const TopUpChannelUpdateSchema = z.object({
  name: z.string().min(2).max(80).optional(),
  account_name: z.string().min(2).max(120).optional(),
  account_reference: z.string().min(3).max(120).optional(),
  instructions: z.string().max(1000).nullable().optional(),
  is_active: z.boolean().optional(),
  reason: z.string().min(3).max(1000),
});

export const ZoneUpdateSchema = z.object({
  is_active: z.boolean(),
  reason: z.string().min(3).max(1000),
});

export const CommissionPolicySchema = z.object({
  rate_basis_points: z.number().int().min(0).max(5000),
  effective_at: z.string().datetime(),
  reason: z.string().min(3).max(1000),
});

export const FareRuleSchema = z.object({
  base_fare: z.number().min(0),
  per_km_rate: z.number().min(0),
  per_minute_rate: z.number().min(0),
  minimum_fare: z.number().min(0),
  surge_multiplier: z.number().min(1).max(3),
  is_active: z.boolean(),
  reason: z.string().min(3).max(1000),
});

export const ComplaintCreateSchema = z.object({
  target_type: z.enum(['ride', 'driver', 'passenger']),
  target_id: z.string().min(1),
  ride_id: z.string().min(1).nullable().optional(),
  category: z.string().min(2).max(120),
  notes: z.string().min(3).max(5000),
  reason: z.string().min(3).max(1000),
});

export const ComplaintUpdateSchema = z.object({
  status: z.enum(['open', 'under_review', 'resolved', 'dismissed']),
  resolution: z.string().trim().max(5000).nullable().optional(),
  reason: z.string().min(3).max(1000),
}).superRefine((value, context) => {
  if (
    (value.status === 'resolved' || value.status === 'dismissed')
    && !value.resolution
  ) {
    context.addIssue({
      code: z.ZodIssueCode.custom,
      message: 'A resolution is required when closing a case',
      path: ['resolution'],
    });
  }
});

export const RestrictionSchema = z.object({
  target_type: z.enum(['driver', 'passenger']),
  target_id: z.string().min(1),
  case_id: z.string().uuid().nullable().optional(),
  ends_at: z.string().datetime().nullable().optional(),
  reason: z.string().min(3).max(1000),
});

export const RestrictionLiftSchema = z.object({
  reason: z.string().min(3).max(1000),
});

export const ManualAssignmentSchema = z.object({
  session_id: z.string().min(1),
  driver_id: z.string().min(1),
  reason: z.string().min(3).max(1000),
});

export const ZoneCheckSchema = z.object({
  pickup_latitude: z.number().min(-90).max(90),
  pickup_longitude: z.number().min(-180).max(180),
  dropoff_latitude: z.number().min(-90).max(90),
  dropoff_longitude: z.number().min(-180).max(180),
});

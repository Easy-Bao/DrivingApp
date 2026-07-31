import { z } from 'zod';
import {
  DEFAULT_COMMISSION_BASIS_POINTS,
  MAXIMUM_CREDIT_BALANCE_CENTAVOS,
  MINIMUM_TOPUP_CENTAVOS,
} from '../entities/driver_operations.types.ts';

const ReasonSchema = z.string().trim().min(3).max(1_000);
const OptionalExpirySchema = z.string().datetime({ offset: true }).nullable().optional();
const DateRangeFields = {
  from: z.string().datetime({ offset: true }).optional(),
  to: z.string().datetime({ offset: true }).optional(),
};

export const PaginationSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(25),
});

export const AdminDriverListQuerySchema = PaginationSchema.extend({
  approvalStatus: z.enum(['pending', 'approved', 'rejected']).optional(),
  ...DateRangeFields,
}).refine((value) => (
  !value.from || !value.to || new Date(value.from) <= new Date(value.to)
), {
  message: 'from must not be after to',
});

export const ApprovalUpdateSchema = z.object({
  status: z.enum(['pending', 'approved', 'rejected']),
  reason: ReasonSchema,
});

export const CreateDocumentRequirementSchema = z.object({
  name: z.string().trim().min(2).max(120),
  isActive: z.boolean().optional(),
  requiresExpiry: z.boolean().optional(),
});

export const UpdateDocumentRequirementSchema = z.object({
  name: z.string().trim().min(2).max(120).optional(),
  isActive: z.boolean().optional(),
  requiresExpiry: z.boolean().optional(),
}).refine((value) => (
  value.name !== undefined
  || value.isActive !== undefined
  || value.requiresExpiry !== undefined
), {
  message: 'At least one field must be supplied',
});

export const ReviewDriverDocumentSchema = z.object({
  status: z.enum(['pending', 'verified', 'rejected', 'expired']),
  expiresAt: OptionalExpirySchema,
  notes: z.string().trim().max(1_000).nullable().optional(),
});

export const CreateRestrictionSchema = z.object({
  reason: ReasonSchema,
  expiresAt: OptionalExpirySchema,
});

export const LiftRestrictionSchema = z.object({
  reason: ReasonSchema,
});

export const CreateTopupChannelSchema = z.object({
  name: z.string().trim().min(2).max(80),
  accountName: z.string().trim().min(2).max(120),
  accountReference: z.string().trim().min(3).max(120),
  instructions: z.string().trim().max(1_000).nullable().optional(),
});

export const UpdateTopupChannelSchema = CreateTopupChannelSchema.partial()
  .extend({ isActive: z.boolean().optional() })
  .refine((value) => Object.keys(value).length > 0, {
    message: 'At least one field must be supplied',
  });

export const CreateTopupRequestSchema = z.object({
  channelId: z.string().trim().min(1).max(128),
  amountCentavos: z.number()
    .int()
    .min(MINIMUM_TOPUP_CENTAVOS)
    .max(MAXIMUM_CREDIT_BALANCE_CENTAVOS),
  senderName: z.string().trim().min(2).max(120),
  transactionReference: z.string().trim().min(3).max(120),
});

export const AdminTopupListQuerySchema = PaginationSchema.extend({
  status: z.enum(['pending', 'approved', 'rejected']).optional(),
  ...DateRangeFields,
}).refine((value) => (
  !value.from || !value.to || new Date(value.from) <= new Date(value.to)
), {
  message: 'from must not be after to',
});

export const ReviewTopupSchema = z.object({
  reason: ReasonSchema,
});

export const CreditAdjustmentSchema = z.object({
  amountCentavos: z.number()
    .int()
    .min(-MAXIMUM_CREDIT_BALANCE_CENTAVOS)
    .max(MAXIMUM_CREDIT_BALANCE_CENTAVOS)
    .refine((amount) => amount !== 0, 'Adjustment cannot be zero'),
  reason: ReasonSchema,
});

export const CreditRefundSchema = z.object({
  amountCentavos: z.number().int().positive().max(MAXIMUM_CREDIT_BALANCE_CENTAVOS),
  reason: ReasonSchema,
});

export const EligibilityRequestSchema = z.object({
  driverId: z.string().trim().min(1).max(128),
  requiredCommissionCentavos: z.number().int().nonnegative().default(0),
});

export const ReserveCreditSchema = z.object({
  driverId: z.string().trim().min(1).max(128),
  rideId: z.string().trim().min(1).max(128),
  fareCentavos: z.number().int().nonnegative().max(100_000_000),
  commissionBasisPoints: z.number()
    .int()
    .min(0)
    .max(10_000)
    .default(DEFAULT_COMMISSION_BASIS_POINTS),
});

export const CreditTransitionSchema = z.object({
  reason: z.string().trim().min(3).max(1_000).optional(),
});

export const CreditDisputeSchema = z.object({
  reason: ReasonSchema,
});

export type ApprovalUpdateRequest = z.infer<typeof ApprovalUpdateSchema>;
export type CreateDocumentRequirementRequest = z.infer<typeof CreateDocumentRequirementSchema>;
export type UpdateDocumentRequirementRequest = z.infer<typeof UpdateDocumentRequirementSchema>;
export type ReviewDriverDocumentRequest = z.infer<typeof ReviewDriverDocumentSchema>;
export type CreateRestrictionRequest = z.infer<typeof CreateRestrictionSchema>;
export type CreateTopupChannelRequest = z.infer<typeof CreateTopupChannelSchema>;
export type UpdateTopupChannelRequest = z.infer<typeof UpdateTopupChannelSchema>;
export type CreateTopupRequest = z.infer<typeof CreateTopupRequestSchema>;
export type CreditAdjustmentRequest = z.infer<typeof CreditAdjustmentSchema>;
export type ReserveCreditRequest = z.infer<typeof ReserveCreditSchema>;

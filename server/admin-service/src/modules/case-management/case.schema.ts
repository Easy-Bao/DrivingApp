import { z } from 'zod';
import { CASE_STATUSES, CASE_TARGET_TYPES } from '../../db/schema/index.ts';

const OptionalDateTime = z.string().datetime({ offset: true }).optional();

export const CaseListQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(25),
  status: z.enum(CASE_STATUSES).optional(),
  from: OptionalDateTime,
  to: OptionalDateTime,
});

export const ComplaintCreateSchema = z.object({
  target_type: z.enum(CASE_TARGET_TYPES),
  target_id: z.string().trim().min(1).max(128),
  ride_id: z.string().trim().min(1).max(128).nullable().optional(),
  category: z.string().trim().min(1).max(80),
  notes: z.string().trim().min(1).max(4_000),
  reason: z.string().trim().min(1).max(500),
});

export const ComplaintUpdateSchema = z.object({
  status: z.enum(CASE_STATUSES),
  resolution: z.string().trim().max(4_000).nullable().optional(),
  reason: z.string().trim().min(1).max(500),
});

export const CaseParamSchema = z.object({
  caseId: z.string().uuid(),
});

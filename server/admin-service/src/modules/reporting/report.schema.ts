import { z } from 'zod';

export const REPORT_TYPES = ['cases', 'audits'] as const;

export const ReportParamSchema = z.object({
  type: z.enum(REPORT_TYPES),
});

export const ReportQuerySchema = z.object({
  from: z.string().datetime({ offset: true }).optional(),
  to: z.string().datetime({ offset: true }).optional(),
  status: z.string().trim().optional(),
  format: z.literal('csv').optional(),
});

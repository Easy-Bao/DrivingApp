import { z } from 'zod';
import { AUDIT_OUTCOMES } from '../../db/schema/index.ts';

const OptionalDateTime = z.string().datetime({ offset: true }).optional();

export const AuditListQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(25),
  status: z.enum(AUDIT_OUTCOMES).optional(),
  from: OptionalDateTime,
  to: OptionalDateTime,
});

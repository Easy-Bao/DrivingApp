import { zValidator } from '@hono/zod-validator';
import { Hono } from 'hono';
import {
  AdminVariables,
  adminAuthMiddleware,
} from '../../common/middleware/auth.ts';
import { AuditListQuerySchema } from './audit.schema.ts';
import { AuditService } from './audit.service.ts';

const auditService = new AuditService();

export const auditRoutes = new Hono<{ Variables: AdminVariables }>();

auditRoutes.use('*', adminAuthMiddleware);
auditRoutes.get('/', zValidator('query', AuditListQuerySchema), async (context) => {
  const query = context.req.valid('query');
  return context.json(await auditService.list(
    query.limit,
    (query.page - 1) * query.limit,
    query.status,
    query.from,
    query.to,
  ));
});

import { zValidator } from '@hono/zod-validator';
import { Hono } from 'hono';
import {
  handleAudits,
  handleCreateCase,
  handleListCases,
  handleOverview,
  handleReport,
  handleUpdateCase,
} from '../controllers/admin.controller.ts';
import {
  handleAdminLogin,
  handleAdminSession,
} from '../controllers/auth.controller.ts';
import {
  AdminLoginSchema,
  AuditListQuerySchema,
  CaseListQuerySchema,
  ComplaintCreateSchema,
  ComplaintUpdateSchema,
} from '../schemas/admin.schema.ts';
import { AdminVariables, adminAuthMiddleware } from '../../shared/middleware/auth.ts';

export const adminRouter = new Hono<{ Variables: AdminVariables }>();

adminRouter.post(
  '/v1/auth/login',
  zValidator('json', AdminLoginSchema),
  handleAdminLogin,
);

adminRouter.use('/v1/*', adminAuthMiddleware);
adminRouter.get('/v1/auth/session', handleAdminSession);
adminRouter.get('/v1/overview', handleOverview);
adminRouter.get('/v1/cases', zValidator('query', CaseListQuerySchema), handleListCases);
adminRouter.post('/v1/cases', zValidator('json', ComplaintCreateSchema), handleCreateCase);
adminRouter.patch(
  '/v1/cases/:caseId',
  zValidator('json', ComplaintUpdateSchema),
  handleUpdateCase,
);
adminRouter.get('/v1/audits', zValidator('query', AuditListQuerySchema), handleAudits);
adminRouter.get('/v1/reports/:type', handleReport);

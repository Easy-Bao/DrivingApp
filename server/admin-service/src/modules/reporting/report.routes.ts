import { zValidator } from '@hono/zod-validator';
import { Hono } from 'hono';
import {
  AdminVariables,
  adminAuthMiddleware,
} from '../../common/middleware/auth.ts';
import { ReportParamSchema, ReportQuerySchema } from './report.schema.ts';
import { ReportService } from './report.service.ts';

const reportService = new ReportService();

export const reportRoutes = new Hono<{ Variables: AdminVariables }>();

reportRoutes.use('*', adminAuthMiddleware);
reportRoutes.get(
  '/:type',
  zValidator('param', ReportParamSchema),
  zValidator('query', ReportQuerySchema),
  async (context) => {
    const type = context.req.valid('param').type;
    const csv = await reportService.export(type, context.req.valid('query'));
    context.header('Content-Type', 'text/csv; charset=utf-8');
    context.header('Content-Disposition', `attachment; filename="easyride-${type}.csv"`);
    return context.body(csv);
  },
);

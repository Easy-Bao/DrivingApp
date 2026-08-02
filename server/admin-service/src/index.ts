import { Hono } from 'hono';
import { globalErrorHandler } from './common/middleware/error.ts';
import { loadAdminConfiguration } from './config/env.ts';
import { auditRoutes } from './modules/audit-log/audit.routes.ts';
import { authRoutes } from './modules/auth/auth.routes.ts';
import { caseRoutes } from './modules/case-management/case.routes.ts';
import { reportRoutes } from './modules/reporting/report.routes.ts';

const configuration = loadAdminConfiguration();

export const app = new Hono();

app.onError(globalErrorHandler);
app.route('/admin/auth', authRoutes);
app.route('/admin', caseRoutes);
app.route('/admin/audits', auditRoutes);
app.route('/admin/reports', reportRoutes);
app.get('/', (context) => context.json({ status: 'Admin Service OK' }));

export default {
  port: configuration.PORT,
  hostname: '0.0.0.0',
  fetch: app.fetch,
};

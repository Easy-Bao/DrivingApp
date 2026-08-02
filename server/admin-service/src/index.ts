import { Hono } from 'hono';
import { loadAdminConfiguration } from './config.ts';
import { adminRouter } from './features/routes/admin.routes.ts';
import { globalErrorHandler } from './shared/middleware/error.ts';

const configuration = loadAdminConfiguration();

export const app = new Hono();

app.onError(globalErrorHandler);
app.route('/admin', adminRouter);
app.get('/', (context) => context.json({ status: 'Admin Service OK' }));

export default {
  port: configuration.PORT,
  hostname: '0.0.0.0',
  fetch: app.fetch,
};

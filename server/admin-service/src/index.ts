import { Hono } from 'hono';
import { adminRouter } from './features/routes/admin.routes.ts';
import { globalErrorHandler } from './shared/middleware/error.ts';

export const app = new Hono();

app.onError(globalErrorHandler);
app.route('/admin', adminRouter);
app.get('/', (context) => context.json({ status: 'Admin Service OK' }));

const port = parseInt(process.env.PORT || '8089', 10);

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
};

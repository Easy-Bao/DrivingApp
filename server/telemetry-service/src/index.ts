import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { telemetryRouter } from './features/telemetry/routes/telemetry.routes.ts';
import { globalErrorHandler } from './shared/middleware/error.ts';

const app = new Hono();

app.use('*', cors());
app.onError(globalErrorHandler);

app.route('/telemetry', telemetryRouter);

app.get('/', (context) => context.json({ status: 'Telemetry Service OK' }));

const port = parseInt(process.env.PORT || '8085');

export { app };

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
};

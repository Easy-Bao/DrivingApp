import { Hono } from 'hono';
import { telemetryRouter } from './features/routes/telemetry.routes.ts';
import { globalErrorHandler } from './shared/middleware/error.ts';
import { createRateLimiter } from './shared/middleware/rate_limiter.ts';

const app = new Hono();

app.use('*', createRateLimiter({ windowMs: 60000, maxRequests: 1200 }));
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

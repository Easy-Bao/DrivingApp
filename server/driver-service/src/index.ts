import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { driversRouter } from './features/routes/driver.routes.ts';
import { handleGetActiveRideRequests } from './features/controllers/driver.controller.ts';
import { globalErrorHandler } from './shared/middleware/error.ts';
import { createRateLimiter } from './shared/middleware/rate_limiter.ts';

const app = new Hono();

app.use('*', cors());
app.use('*', createRateLimiter({ windowMs: 60000, maxRequests: 60 }));
app.onError(globalErrorHandler);

app.route('/drivers', driversRouter);

app.get('/rides/active', handleGetActiveRideRequests);

app.get('/', (c) => c.json({ status: 'Driver Service OK' }));

const port = parseInt(process.env.PORT || '8082');

export { app };

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
};

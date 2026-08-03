import { Hono } from 'hono';
import { driversRouter } from './features/routes/driver.routes.ts';
import { handleGetActiveRideRequests } from './features/controllers/driver.controller.ts';
import { globalErrorHandler } from './shared/middleware/error.ts';
import { createRateLimiter } from './shared/middleware/rate_limiter.ts';

const app = new Hono();

app.use('*', createRateLimiter({ windowMs: 60000, maxRequests: 600 }));
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

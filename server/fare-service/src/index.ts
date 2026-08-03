import { Hono } from 'hono';
import { fareRouter } from './features/routes/fare.routes.ts';
import { globalErrorHandler } from './shared/middleware/error.ts';
import { createRateLimiter } from './shared/middleware/rate_limiter.ts';

const app = new Hono();

app.use('*', createRateLimiter({ windowMs: 60000, maxRequests: 600 }));
app.onError(globalErrorHandler);

app.route('/fares', fareRouter);

app.get('/', (c) => c.json({ status: 'Fare Service OK' }));

const port = parseInt(process.env.PORT || '8087');

export { app };

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
};

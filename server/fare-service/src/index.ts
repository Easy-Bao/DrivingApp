import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { fareRouter } from './features/routes/fare.routes.ts';
import { globalErrorHandler } from './shared/middleware/error.ts';
import { createRateLimiter } from './shared/middleware/rate_limiter.ts';
import { seedPricingRules } from './db/seed.ts';

const app = new Hono();

app.use('*', cors());
app.use('*', createRateLimiter({ windowMs: 60000, maxRequests: 100 }));
app.onError(globalErrorHandler);

app.route('/fares', fareRouter);

app.get('/', (c) => c.json({ status: 'Fare Service OK' }));

const port = parseInt(process.env.PORT || '8087');

seedPricingRules().catch((err) => {
  console.error('[FareService Startup] Seed failed:', err);
});

export { app };

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
};

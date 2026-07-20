import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { ridesRouter } from './features/routes/ride.routes.ts';
import { globalErrorHandler } from './shared/middleware/error.ts';
import { createRateLimiter } from './shared/middleware/rate_limiter.ts';

const app = new Hono();

app.use('*', cors());
app.use('*', createRateLimiter({ windowMs: 60000, maxRequests: 60 }));
app.onError(globalErrorHandler);

app.route('/rides', ridesRouter);

app.get('/', (context) => context.json({ status: 'Trip Service OK' }));

const port = parseInt(process.env.PORT || '8083');

export { app };

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
};

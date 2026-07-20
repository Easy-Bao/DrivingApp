import { Hono } from 'hono';
import { passengerRouter } from './features/routes/passenger.routes.ts';
import { globalErrorHandler } from './shared/middleware/error.ts';
import { createRateLimiter } from './shared/middleware/rate_limiter.ts';

const port = parseInt(process.env.PORT || '8081', 10);

const app = new Hono();

app.use('*', createRateLimiter({ windowMs: 60000, maxRequests: 60 }));
app.onError(globalErrorHandler);

app.get('/', (c) => c.text('Passenger service active'));

app.route('/', passengerRouter);

console.log(`Passenger service is listening at: http://0.0.0.0:${port}`);

export { app };

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
};

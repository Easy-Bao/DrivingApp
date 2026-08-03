import { Hono } from 'hono';
import { websocket } from 'hono/bun';
import { gatewayRouter } from './routes/gateway.ts';
import { createRateLimiter } from './middleware/rate_limiter.ts';

export const app = new Hono();

app.use('*', createRateLimiter({ windowMs: 60000, maxRequests: 600 }));
app.route('/', gatewayRouter);
app.get('/', (context) => context.json({ status: 'Gateway OK' }));

const port = parseInt(process.env.PORT || '8080');

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
  websocket,
};

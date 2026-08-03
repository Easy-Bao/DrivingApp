import { Hono } from 'hono';
import { websocket } from 'hono/bun';
import { chatRouter } from './features/routes/chat.routes.ts';
import { globalErrorHandler } from './shared/middleware/error.ts';
import { createRateLimiter } from './shared/middleware/rate_limiter.ts';

const app = new Hono();

app.use('*', createRateLimiter({ windowMs: 60000, maxRequests: 600 }));
app.onError(globalErrorHandler);

app.route('/chat', chatRouter);

app.get('/', (context) => context.json({ status: 'Chat Service OK' }));

const port = parseInt(process.env.PORT || '8086');

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
  websocket,
};

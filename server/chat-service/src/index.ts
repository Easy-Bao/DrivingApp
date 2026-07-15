import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { websocket } from 'hono/bun';
import { chatRouter } from './features/chat/routes/chat.routes.ts';
import { globalErrorHandler } from './shared/middleware/error.ts';

const app = new Hono();

app.use('*', cors());
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

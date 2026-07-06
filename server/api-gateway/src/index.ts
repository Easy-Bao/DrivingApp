import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { websocket } from 'hono/bun';
import { gatewayRouter } from './routes/gateway.ts';

const app = new Hono();

app.use('*', cors());

app.route('/', gatewayRouter);

app.get('/', (c) => c.json({ status: 'Gateway OK' }));

const port = parseInt(process.env.PORT || '8080');

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
  websocket,
};

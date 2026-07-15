/**
 * Entry point for api-gateway — registers CORS, mounts the gateway router, and exports
 * the Bun server config with the WebSocket handler attached.
 */
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { websocket } from 'hono/bun';
import { gatewayRouter } from './routes/gateway.ts';

export const app = new Hono();

app.use('*', cors());
app.route('/', gatewayRouter);
app.get('/', (context) => context.json({ status: 'Gateway OK' }));

const port = parseInt(process.env.PORT || '8080');

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
  websocket,
};

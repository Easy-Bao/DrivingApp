import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { telemetryRouter } from './routes/telemetry.ts';

const app = new Hono();

app.use('*', cors());

app.route('/telemetry', telemetryRouter);

app.get('/', (c) => c.json({ status: 'Telemetry Service OK' }));

const port = parseInt(process.env.PORT || '8085');

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
};

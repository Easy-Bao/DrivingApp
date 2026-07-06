import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { driversRouter } from './routes/drivers.ts';
import { ridesRouter } from './routes/rides.ts';

const app = new Hono();

app.use('*', cors());

app.route('/drivers', driversRouter);
app.route('/rides', ridesRouter);

app.get('/', (c) => c.json({ status: 'Driver Service OK' }));

const port = parseInt(process.env.PORT || '8082');

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
};

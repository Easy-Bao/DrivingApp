import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { ridesRouter } from './routes/rides.ts';

const app = new Hono();

app.use('*', cors());

app.route('/rides', ridesRouter);

app.get('/', (context) => context.json({ status: 'Trip Service OK' }));

const port = parseInt(process.env.PORT || '8083');

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
};

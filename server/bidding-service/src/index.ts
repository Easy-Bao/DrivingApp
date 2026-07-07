import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { bidsRouter } from './routes/bids.ts';

const app = new Hono();

app.use('*', cors());

app.route('/bids', bidsRouter);

app.get('/', (context) => context.json({ status: 'Bidding Service OK' }));

const port = parseInt(process.env.PORT || '8084');

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
};

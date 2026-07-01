import { Hono } from 'hono';
import { cors } from 'hono/cors';

const app = new Hono();

app.use('*', cors());

app.get('/', (c) => c.json({ status: 'Bidding Service OK' }));

const port = parseInt(process.env.PORT || '8084');
console.log(`Bidding Service listening on port ${port}`);

export default {
  port,
  fetch: app.fetch,
};

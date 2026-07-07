import { Hono } from 'hono';

import { getPassengerRouter } from './passenger/routes.ts';
import { InMemoryPassengerRepository, PrismaPassengerRepository } from './passenger/index.ts';

const port = parseInt(process.env.PORT || '8081', 10);
const databaseUrl = process.env.DATABASE_URL;

const repo = databaseUrl
  ? new PrismaPassengerRepository()
  : new InMemoryPassengerRepository();

const app = new Hono();

app.get('/', (c) => c.text('Passenger service active'));

const passengerRouter = getPassengerRouter(repo);
app.route('/', passengerRouter);

console.log(`Passenger service is listening at: http://0.0.0.0:${port}`);

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
};

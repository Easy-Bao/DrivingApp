import { Hono } from 'hono';

import { getPassengerRouter } from './passenger/routes.ts';
import { InMemoryPassengerRepository, PostgresPassengerRepository } from './passenger/repository.ts';

const port = parseInt(process.env.PORT || '8081', 10);
const databaseUrl = process.env.DATABASE_URL;

const repo = databaseUrl
  ? new PostgresPassengerRepository()
  : new InMemoryPassengerRepository();

const app = new Hono();

app.get('/', (c) => c.text('Passenger service active'));

const passengerRouter = getPassengerRouter(repo);
app.route('/', passengerRouter);

console.log(`Passenger service is listening at: http://localhost:${port}`);

export default {
  port,
  fetch: app.fetch,
};

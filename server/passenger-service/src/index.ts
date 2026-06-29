/**
 * Server entrypoint: loads configurations, runs database schema migrations, maps API routes, and launches the Hono server on port 8081.
 */
import { Hono } from 'hono';
import { runMigrations } from './db.ts';
import { getPassengerRouter } from './passenger/routes.ts';
import { InMemoryPassengerRepository, PostgresPassengerRepository } from './passenger/repository.ts';

const port = parseInt(process.env.PORT || '8081', 10);
const databaseUrl = process.env.DATABASE_URL;

await runMigrations();

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

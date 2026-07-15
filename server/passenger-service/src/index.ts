/**
 * Entry point for passenger-service registering Hono routes and mounting error handle middleware.
 */
import { Hono } from 'hono';
import { passengerRouter } from './features/passenger/routes/passenger.routes.ts';
import { globalErrorHandler } from './shared/middleware/error.ts';

const port = parseInt(process.env.PORT || '8081', 10);

const app = new Hono();

app.onError(globalErrorHandler);

app.get('/', (c) => c.text('Passenger service active'));

// Mount modular passenger routes
app.route('/', passengerRouter);

console.log(`Passenger service is listening at: http://0.0.0.0:${port}`);

export { app };

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
};

/**
 * Entry point for driver-service registering routes and mounting error handlers.
 */
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { driversRouter } from './features/driver/routes/driver.routes.ts';
import { handleGetActiveRideRequests } from './features/driver/controllers/driver.controller.ts';
import { globalErrorHandler } from './shared/middleware/error.ts';

const app = new Hono();

app.use('*', cors());
app.onError(globalErrorHandler);

// Mount modular driver routes
app.route('/drivers', driversRouter);

// Maintain compatibility for legacy active rides route
app.get('/rides/active', handleGetActiveRideRequests);

app.get('/', (c) => c.json({ status: 'Driver Service OK' }));

const port = parseInt(process.env.PORT || '8082');

export { app };

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
};

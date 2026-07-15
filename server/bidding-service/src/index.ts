/**
 * Entry point for bidding-service registering routes and mounting error handlers.
 */
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { biddingRouter } from './features/bidding/routes/bidding.routes.ts';
import { globalErrorHandler } from './shared/middleware/error.ts';

const app = new Hono();

app.use('*', cors());
app.onError(globalErrorHandler);

// Mount modular bidding routes
app.route('/bids', biddingRouter);

app.get('/', (context) => context.json({ status: 'Bidding Service OK' }));

const port = parseInt(process.env.PORT || '8084');

export { app };

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
};

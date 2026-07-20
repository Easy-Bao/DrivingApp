/**
 * Entry point for bidding-service registering routes, mounting error handlers, and bootstrapping
 * the session-expiry background worker. The worker runs every 60 seconds on an interval rather
 * than inline on read requests, keeping the hot GET /bids/active path free of DB write locks.
 */
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { biddingRouter } from './features/routes/bidding.routes.ts';
import { globalErrorHandler } from './shared/middleware/error.ts';
import { DrizzleBiddingRepository } from './features/repositories/bidding.repository.ts';
import { Logger } from './shared/logger/logger.ts';
import { createRateLimiter } from './shared/middleware/rate_limiter.ts';

const app = new Hono();

app.use('*', cors());
app.use('*', createRateLimiter({ windowMs: 60000, maxRequests: 60 }));
app.onError(globalErrorHandler);

app.route('/bids', biddingRouter);

app.get('/', (context) => context.json({ status: 'Bidding Service OK' }));

const SESSION_EXPIRY_INTERVAL_MS = 60_000;

function startSessionExpiryWorker(): void {
  const repository = new DrizzleBiddingRepository();
  setInterval(async () => {
    try {
      await repository.expireSessions(new Date());
    } catch (err) {
      Logger.error('Session expiry worker encountered an error:', err);
    }
  }, SESSION_EXPIRY_INTERVAL_MS);
  Logger.info(`Session expiry worker started (interval: ${SESSION_EXPIRY_INTERVAL_MS}ms)`);
}

startSessionExpiryWorker();

const port = parseInt(process.env.PORT || '8084');

export { app };

export default {
  port,
  hostname: '0.0.0.0',
  fetch: app.fetch,
};

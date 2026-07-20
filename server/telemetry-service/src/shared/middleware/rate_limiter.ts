import { Context, Next } from 'hono';

export interface RateLimiterOptions {
  windowMs: number;
  maxRequests: number;
  message?: string;
}

export function createRateLimiter(options: RateLimiterOptions) {
  const { windowMs, maxRequests, message = 'Too many requests, please try again later.' } = options;
  const clientRequestTimestampsMap = new Map<string, number[]>();

  return async (context: Context, next: Next) => {
    const clientIdentifierKey =
      context.req.header('x-forwarded-for') ||
      context.req.header('x-real-ip') ||
      'anonymous-client';
    const currentTimestampMs = Date.now();
    const windowStartTimestampMs = currentTimestampMs - windowMs;

    const clientTimestampsList = clientRequestTimestampsMap.get(clientIdentifierKey) || [];
    const activeTimestampsList = clientTimestampsList.filter(
      (timestampMs) => timestampMs > windowStartTimestampMs
    );

    if (activeTimestampsList.length >= maxRequests) {
      context.header('Retry-After', Math.ceil(windowMs / 1000).toString());
      return context.json({ success: false, error: message }, 429);
    }

    activeTimestampsList.push(currentTimestampMs);
    clientRequestTimestampsMap.set(clientIdentifierKey, activeTimestampsList);

    await next();
  };
}

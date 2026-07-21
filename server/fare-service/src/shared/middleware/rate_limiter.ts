import type { MiddlewareHandler } from 'hono';

interface RateLimiterOptions {
  windowMs: number;
  maxRequests: number;
}

export function createRateLimiter(options: RateLimiterOptions): MiddlewareHandler {
  const requestsMap = new Map<string, { count: number; resetTime: number }>();

  return async (c, next) => {
    const ip = c.req.header('x-forwarded-for') || '127.0.0.1';
    const now = Date.now();

    let record = requestsMap.get(ip);
    if (!record || now > record.resetTime) {
      record = { count: 1, resetTime: now + options.windowMs };
      requestsMap.set(ip, record);
    } else {
      record.count += 1;
    }

    if (record.count > options.maxRequests) {
      return c.json(
        {
          success: false,
          error: {
            name: 'TooManyRequests',
            message: 'Rate limit exceeded. Please try again later.',
          },
        },
        429,
      );
    }

    await next();
  };
}

import { describe, expect, test } from 'bun:test';
import { Hono } from 'hono';
import { sign } from 'hono/jwt';
import { HTTPException } from 'hono/http-exception';
import {
  AuthVariables,
  authMiddleware,
  internalAuthMiddleware,
  requireRole,
} from '../../src/shared/middleware/auth.ts';
import {
  CreateBidSessionSchema,
  PlaceOfferSchema,
} from '../../src/features/schemas/bidding.schema.ts';
import { globalErrorHandler } from '../../src/shared/middleware/error.ts';

process.env.JWT_SECRET = 'bidding-test-jwt-secret';
process.env.INTERNAL_SERVICE_TOKEN = 'bidding-test-internal-secret';

const app = new Hono<{ Variables: AuthVariables }>();
app.onError(globalErrorHandler);
app.post(
  '/passenger',
  authMiddleware,
  requireRole('passenger'),
  (context) => context.json({ userId: context.get('userId') }),
);
app.post(
  '/internal',
  internalAuthMiddleware,
  (context) => context.json({ ok: true }),
);
app.post(
  '/business-error',
  authMiddleware,
  requireRole('passenger'),
  () => {
    throw new HTTPException(409, { message: 'INSUFFICIENT_CREDIT' });
  },
);

describe('bidding authentication middleware', () => {
  test('rejects unauthenticated and wrong-role public mutations', async () => {
    expect((await app.request('/passenger', { method: 'POST' })).status).toBe(401);

    const driverToken = await sign({
      sub: 'driver-real',
      role: 'driver',
      exp: Math.floor(Date.now() / 1000) + 60,
    }, process.env.JWT_SECRET!);
    const response = await app.request('/passenger', {
      method: 'POST',
      headers: { Authorization: `Bearer ${driverToken}` },
    });
    expect(response.status).toBe(403);
  });

  test('derives the caller ID from a valid JWT', async () => {
    const passengerToken = await sign({
      sub: 'passenger-real',
      role: 'passenger',
      exp: Math.floor(Date.now() / 1000) + 60,
    }, process.env.JWT_SECRET!);
    const response = await app.request('/passenger', {
      method: 'POST',
      headers: { Authorization: `Bearer ${passengerToken}` },
    });
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ userId: 'passenger-real' });
  });

  test('does not turn downstream business errors into authentication failures', async () => {
    const passengerToken = await sign({
      sub: 'passenger-real',
      role: 'passenger',
      exp: Math.floor(Date.now() / 1000) + 60,
    }, process.env.JWT_SECRET!);
    const response = await app.request('/business-error', {
      method: 'POST',
      headers: { Authorization: `Bearer ${passengerToken}` },
    });
    expect(response.status).toBe(409);
    expect(await response.json()).toMatchObject({ code: 'INSUFFICIENT_CREDIT' });
  });

  test('requires the configured internal service token', async () => {
    expect((await app.request('/internal', { method: 'POST' })).status).toBe(403);
    expect((await app.request('/internal', {
      method: 'POST',
      headers: {
        'X-Internal-Service-Token': process.env.INTERNAL_SERVICE_TOKEN!,
      },
    })).status).toBe(200);
  });

  test('strips client-supplied passenger and driver identity fields', () => {
    const session = CreateBidSessionSchema.parse({
      passenger_id: 'passenger-spoofed',
      ride_type: 'Solo Ride',
      pickup_latitude: 7.82,
      pickup_longitude: 123.43,
      dropoff_latitude: 7.83,
      dropoff_longitude: 123.44,
      distance_km: 5,
      duration_minutes: 10,
    });
    const offer = PlaceOfferSchema.parse({
      driver_id: 'driver-spoofed',
      driver_name: 'Spoofed Name',
      proposed_fare: 95,
    });

    expect('passenger_id' in session).toBe(false);
    expect('driver_id' in offer).toBe(false);
    expect('driver_name' in offer).toBe(false);
  });
});

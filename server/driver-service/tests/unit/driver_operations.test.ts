import { describe, expect, test } from 'bun:test';
import { Hono } from 'hono';
import { sign } from 'hono/jwt';
import {
  calculateCommissionCentavos,
  DriverDomainError,
  hashIdempotencyPayload,
  normalizePaymentReference,
} from '../../src/features/entities/driver_operations.types.ts';
import {
  CreateTopupRequestSchema,
  ReserveCreditSchema,
} from '../../src/features/schemas/driver_operations.schema.ts';
import {
  driverAuthMiddleware,
  DriverAuthEnvironment,
  internalServiceMiddleware,
} from '../../src/shared/middleware/auth.ts';

describe('driver service-credit rules', () => {
  test('calculates the 10% commission in exact centavos', () => {
    expect(calculateCommissionCentavos(12_345)).toBe(1_235);
    expect(calculateCommissionCentavos(10_000, 500)).toBe(500);
  });

  test('rejects invalid money and commission values', () => {
    expect(() => calculateCommissionCentavos(1.25)).toThrow(DriverDomainError);
    expect(() => calculateCommissionCentavos(100, 10_001)).toThrow(
      DriverDomainError,
    );
  });

  test('normalizes payment references before duplicate checking', () => {
    expect(normalizePaymentReference('  GC 123 456 ')).toBe('gc123456');
  });

  test('enforces ₱100 minimum and ₱1,000 maximum top-ups', () => {
    const base = {
      channelId: 'gcash',
      senderName: 'Test Driver',
      transactionReference: 'REF-123',
    };
    expect(CreateTopupRequestSchema.safeParse({
      ...base,
      amountCentavos: 9_999,
    }).success).toBe(false);
    expect(CreateTopupRequestSchema.safeParse({
      ...base,
      amountCentavos: 10_000,
    }).success).toBe(true);
    expect(CreateTopupRequestSchema.safeParse({
      ...base,
      amountCentavos: 100_001,
    }).success).toBe(false);
  });

  test('defaults ride reservations to a 10% commission', () => {
    const parsed = ReserveCreditSchema.parse({
      driverId: 'drv_test',
      rideId: 'ride_test',
      fareCentavos: 25_000,
    });
    expect(parsed.commissionBasisPoints).toBe(1_000);
  });

  test('hashes identical idempotency payloads consistently', async () => {
    const first = await hashIdempotencyPayload({ rideId: 'ride_1', amount: 10 });
    const second = await hashIdempotencyPayload({ rideId: 'ride_1', amount: 10 });
    expect(first).toBe(second);
    expect(first).toHaveLength(64);
  });
});

describe('driver-service authentication boundaries', () => {
  test('accepts only a driver JWT on public self-service routes', async () => {
    process.env.JWT_SECRET = 'driver-service-unit-test-secret';
    const app = new Hono<DriverAuthEnvironment>();
    app.use('*', driverAuthMiddleware);
    app.get('/', (context) => context.json({ driverId: context.get('driverId') }));

    const driverToken = await sign(
      { sub: 'drv_1', email: 'driver@test.local', role: 'driver' },
      process.env.JWT_SECRET,
      'HS256',
    );
    const accepted = await app.request('/', {
      headers: { Authorization: `Bearer ${driverToken}` },
    });
    expect(accepted.status).toBe(200);
    expect(await accepted.json()).toEqual({ driverId: 'drv_1' });

    const passengerToken = await sign(
      { sub: 'psg_1', email: 'passenger@test.local', role: 'passenger' },
      process.env.JWT_SECRET,
      'HS256',
    );
    const rejected = await app.request('/', {
      headers: { Authorization: `Bearer ${passengerToken}` },
    });
    expect(rejected.status).toBe(401);
  });

  test('requires the exact internal service token', async () => {
    process.env.INTERNAL_SERVICE_TOKEN = 'internal-unit-test-token';
    const app = new Hono();
    app.use('*', internalServiceMiddleware);
    app.get('/', (context) => context.json({ ok: true }));

    expect((await app.request('/')).status).toBe(401);
    expect((await app.request('/', {
      headers: { 'x-internal-service-token': 'wrong-token' },
    })).status).toBe(401);
    expect((await app.request('/', {
      headers: {
        'x-internal-service-token': process.env.INTERNAL_SERVICE_TOKEN,
      },
    })).status).toBe(200);
  });
});

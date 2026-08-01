import { describe, expect, test } from 'bun:test';
import { Hono } from 'hono';
import { sign } from 'hono/jwt';
import {
  calculateCommissionCentavos,
  DriverDomainError,
  getEffectiveDocumentStatus,
  hashIdempotencyPayload,
  isDocumentRequirementSatisfied,
  normalizePaymentReference,
  validateDocumentReviewExpiry,
} from '../../src/features/entities/driver_operations.types.ts';
import {
  AdminDriverListQuerySchema,
  AdminTopupListQuerySchema,
  CreateDocumentRequirementSchema,
  CreateTopupRequestSchema,
  ReserveCreditSchema,
  UpdateDocumentRequirementSchema,
} from '../../src/features/schemas/driver_operations.schema.ts';
import {
  driverAuthMiddleware,
  DriverAuthEnvironment,
  internalServiceMiddleware,
} from '../../src/shared/middleware/auth.ts';

const databaseTest = process.env.DATABASE_URL ? test : test.skip;

describe('driver service-credit rules', () => {
  test('validates Admin report date ranges', () => {
    const valid = {
      from: '2026-07-01T00:00:00.000Z',
      to: '2026-07-31T23:59:59.999Z',
    };
    expect(AdminDriverListQuerySchema.safeParse(valid).success).toBe(true);
    expect(AdminTopupListQuerySchema.safeParse(valid).success).toBe(true);
    expect(AdminDriverListQuerySchema.safeParse({
      ...valid,
      from: '2026-08-01T00:00:00.000Z',
    }).success).toBe(false);
  });

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

describe('driver document requirement rules', () => {
  const now = new Date('2026-07-31T00:00:00.000Z');
  const verifiedWithoutExpiry = {
    status: 'verified' as const,
    expiresAt: null,
  };

  test('accepts additive expiry and active-state fields at API boundaries', () => {
    expect(CreateDocumentRequirementSchema.parse({
      name: 'Driver License',
      isActive: false,
      requiresExpiry: true,
    })).toEqual({
      name: 'Driver License',
      isActive: false,
      requiresExpiry: true,
    });
    expect(UpdateDocumentRequirementSchema.parse({
      isActive: false,
      requiresExpiry: true,
    })).toEqual({
      isActive: false,
      requiresExpiry: true,
    });
    expect(UpdateDocumentRequirementSchema.safeParse({}).success).toBe(false);
  });

  test('requires a future expiry only when a verified requirement says so', () => {
    expect(() => validateDocumentReviewExpiry(
      { requiresExpiry: true },
      'verified',
      null,
      now,
    )).toThrow(DriverDomainError);
    expect(() => validateDocumentReviewExpiry(
      { requiresExpiry: true },
      'verified',
      new Date('2026-07-30T23:59:59.000Z'),
      now,
    )).toThrow(DriverDomainError);
    expect(() => validateDocumentReviewExpiry(
      { requiresExpiry: false },
      'verified',
      null,
      now,
    )).not.toThrow();
  });

  test('reevaluates existing checks when expiry policy or active state changes', () => {
    expect(getEffectiveDocumentStatus(
      { requiresExpiry: false },
      verifiedWithoutExpiry,
      now,
    )).toBe('verified');
    expect(getEffectiveDocumentStatus(
      { requiresExpiry: true },
      verifiedWithoutExpiry,
      now,
    )).toBe('pending');
    expect(isDocumentRequirementSatisfied(
      { isActive: true, requiresExpiry: true },
      verifiedWithoutExpiry,
      now,
    )).toBe(false);
    expect(isDocumentRequirementSatisfied(
      { isActive: false, requiresExpiry: true },
      null,
      now,
    )).toBe(true);
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

  databaseTest('reports missing Admin actor and idempotency headers accurately', async () => {
    process.env.INTERNAL_SERVICE_TOKEN = 'internal-unit-test-token';
    const { app } = await import('../../src/index.ts');
    const body = JSON.stringify({ name: 'Driver License' });
    const baseHeaders = {
      'content-type': 'application/json',
      'x-internal-service-token': process.env.INTERNAL_SERVICE_TOKEN,
    };

    const missingActor = await app.request('/drivers/admin/document-requirements', {
      method: 'POST',
      headers: baseHeaders,
      body,
    });
    expect(missingActor.status).toBe(422);
    expect(await missingActor.json()).toMatchObject({ code: 'INVALID_ACTOR' });

    const missingIdempotencyKey = await app.request(
      '/drivers/admin/document-requirements',
      {
        method: 'POST',
        headers: {
          ...baseHeaders,
          'x-admin-id': 'owner-1',
        },
        body,
      },
    );
    expect(missingIdempotencyKey.status).toBe(422);
    expect(await missingIdempotencyKey.json()).toMatchObject({
      code: 'INVALID_IDEMPOTENCY_KEY',
    });
  });
});

import { describe, expect, test } from 'bun:test';
import { eq, sql } from 'drizzle-orm';
import { fareTransactions } from '../../src/db/schema.ts';
import { FareCalculationService } from '../../src/features/services/fare_calculation.service.ts';
import { db } from '../../src/shared/drizzle.ts';

function snapshot(rideId: string) {
  return {
    rideId,
    driverId: 'driver-test',
    serviceType: 'Solo Ride',
    totalFareCentavos: 12_345,
    commissionRateBasisPoints: 1_000,
    commissionCentavos: 1_235,
    assignmentSource: 'driver_offer' as const,
  };
}

describe('fare snapshot invariants', () => {
  test('stores one immutable monetary snapshot for repeated requests', async () => {
    const service = new FareCalculationService();
    const input = snapshot(`fare-snapshot-${crypto.randomUUID()}`);

    const results = await Promise.all([
      service.recordFareSnapshot(input),
      service.recordFareSnapshot(input),
      service.recordFareSnapshot(input),
    ]);

    expect(new Set(results.map(({ id }) => id))).toHaveLength(1);
    expect(results[0]).toMatchObject({
      totalFareCentavos: 12_345,
      platformFeeCentavos: 1_235,
      driverEarningsCentavos: 11_110,
      commissionRateBasisPoints: 1_000,
    });
    await expect(service.recordFareSnapshot({
      ...input,
      serviceType: 'Bao Premium',
    })).rejects.toThrow('IDEMPOTENCY_KEY_REUSED');
  });

  test('rejects a commission amount that does not match the snapped rate', async () => {
    const service = new FareCalculationService();

    await expect(service.recordFareSnapshot({
      ...snapshot(`fare-invalid-${crypto.randomUUID()}`),
      commissionCentavos: 1_234,
    })).rejects.toThrow('INVALID_COMMISSION_SNAPSHOT');
  });

  test('does not apply a later commission rate to an existing ride', async () => {
    const service = new FareCalculationService();
    const original = await service.recordFareSnapshot(
      snapshot(`fare-original-policy-${crypto.randomUUID()}`),
    );
    await service.recordFareSnapshot({
      ...snapshot(`fare-later-policy-${crypto.randomUUID()}`),
      commissionRateBasisPoints: 1_250,
      commissionCentavos: 1_543,
    });

    const [unchanged] = await db.select()
      .from(fareTransactions)
      .where(eq(fareTransactions.id, original.id));
    expect(unchanged).toMatchObject({
      commissionRateBasisPoints: 1_000,
      platformFeeCentavos: 1_235,
    });
  });

  test('allows status updates while keeping snapshot rows append-only', async () => {
    const service = new FareCalculationService();
    const input = snapshot(`fare-immutable-${crypto.randomUUID()}`);
    const created = await service.recordFareSnapshot(input);

    const received = await service.updatePaymentStatus(input.rideId, 'cash_received');
    expect(received.paymentStatus).toBe('cash_received');

    await expect((async () => {
      await db.update(fareTransactions)
        .set({ commissionRateBasisPoints: 2_000 })
        .where(eq(fareTransactions.id, created.id));
    })())
      .rejects.toThrow('fare transaction snapshot is immutable');
    await expect((async () => {
      await db.execute(sql`
        delete from fare_transactions where id = ${created.id}
      `);
    })()).rejects.toThrow('fare transaction snapshot is immutable');

    const [unchanged] = await db.select()
      .from(fareTransactions)
      .where(eq(fareTransactions.id, created.id));
    expect(unchanged).toMatchObject({
      paymentStatus: 'cash_received',
      commissionRateBasisPoints: 1_000,
      platformFeeCentavos: 1_235,
    });
  });

  test('allows only one competing terminal payment outcome', async () => {
    const service = new FareCalculationService();
    const input = snapshot(`fare-status-${crypto.randomUUID()}`);
    await service.recordFareSnapshot(input);

    const outcomes = await Promise.allSettled([
      service.updatePaymentStatus(input.rideId, 'cash_received'),
      service.updatePaymentStatus(input.rideId, 'canceled'),
    ]);
    const succeeded = outcomes.filter(({ status }) => status === 'fulfilled');
    const failed = outcomes.filter(({ status }) => status === 'rejected');

    expect(succeeded).toHaveLength(1);
    expect(failed).toHaveLength(1);
    expect((failed[0] as PromiseRejectedResult).reason.message).toBe(
      'FARE_STATUS_CONFLICT',
    );
  });

  test('database rejects an inconsistent centavo snapshot', async () => {
    await expect((async () => {
      await db.insert(fareTransactions).values({
        rideId: `fare-db-invalid-${crypto.randomUUID()}`,
        driverId: 'driver-test',
        serviceType: 'Solo Ride',
        distanceKm: 0,
        durationMinutes: 0,
        baseFare: 123.45,
        distanceCharge: 0,
        timeCharge: 0,
        surgeCharge: 0,
        totalFare: 123.45,
        driverEarnings: 111.11,
        platformFee: 12.34,
        totalFareCentavos: 12_345,
        driverEarningsCentavos: 11_111,
        platformFeeCentavos: 1_234,
        commissionRateBasisPoints: 1_000,
        assignmentSource: 'driver_offer',
      });
    })()).rejects.toThrow('fare_transactions_snapshot_integrity');
  });
});

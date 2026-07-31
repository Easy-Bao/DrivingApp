import { beforeEach, describe, expect, test } from 'bun:test';
import { sql } from 'drizzle-orm';
import { drivers } from '../../src/db/schema.ts';
import {
  DriverDomainError,
} from '../../src/features/entities/driver_operations.types.ts';
import { DriverRepositoryImpl } from '../../src/features/repositories/driver.repository.ts';
import { DriverOperationsRepository } from '../../src/features/repositories/driver_operations.repository.ts';
import { DriverOperationsService } from '../../src/features/services/driver_operations.service.ts';
import { db } from '../../src/shared/drizzle.ts';

const driverId = 'drv_operations_test';
const repository = new DriverOperationsRepository();
const service = new DriverOperationsService(
  repository,
  new DriverRepositoryImpl(),
);

const databaseDescribe = process.env.RUN_DRIVER_OPERATIONS_INTEGRATION === '1'
  ? describe
  : describe.skip;

databaseDescribe('driver compliance and credit transactions', () => {
  beforeEach(async () => {
    await db.execute(sql`
      truncate table
        driver_idempotency_records,
        driver_credit_ledger,
        driver_credit_reservations,
        driver_topup_requests,
        driver_topup_channels,
        driver_credit_wallets,
        driver_account_restrictions,
        driver_document_checks,
        driver_document_requirements,
        reviews,
        drivers
      restart identity cascade
    `);
    await db.insert(drivers).values({
      id: driverId,
      name: 'Operations Test Driver',
      email: 'operations-driver@test.local',
      phone: '09000000000',
      vehicleType: 'Bao Bao',
      plateNumber: 'TEST 001',
      passwordHash: 'not-a-real-password',
    });
  });

  test('enforces compliance, reserves once, and settles exact commission', async () => {
    const requirement = await service.createDocumentRequirement(
      { name: 'Driver License' },
      'admin_owner',
      'requirement-create-1',
    );
    await service.updateApproval(
      driverId,
      { status: 'approved', reason: 'Paperwork checked' },
      'admin_owner',
      'approval-1',
    );
    await service.reviewDriverDocument(
      driverId,
      requirement.id,
      {
        status: 'verified',
        expiresAt: '2028-01-01T00:00:00.000Z',
        notes: 'Original inspected',
      },
      'admin_owner',
      'document-review-1',
    );
    await service.adjustCredits(
      driverId,
      { amountCentavos: 50_000, reason: 'Test opening balance' },
      'admin_owner',
      'adjustment-1',
    );

    const adminList = await service.listDrivers(1, 25, 'approved');
    expect(adminList.items[0]).toMatchObject({
      id: driverId,
      documentStatus: 'verified',
      restrictionStatus: 'none',
    });
    expect('passwordHash' in adminList.items[0]).toBe(false);
    expect((await service.checkEligibility(driverId, 1_235)).eligible).toBe(true);
    const reservationInput = {
      driverId,
      rideId: 'ride_1',
      fareCentavos: 12_345,
      commissionBasisPoints: 1_000,
    };
    const [reservation, replay] = await Promise.all([
      service.reserveCredits(
        reservationInput,
        'trip-service',
        'reserve-1',
      ),
      service.reserveCredits(
        reservationInput,
        'trip-service',
        'reserve-2',
      ),
    ]);
    expect(reservation.commissionCentavos).toBe(1_235);
    expect(replay.reservation.id).toBe(reservation.reservation.id);

    await service.transitionReservation(
      'ride_1',
      'settled',
      'Ride completed',
      'trip-service',
      'settle-1',
    );
    await service.transitionReservation(
      'ride_1',
      'settled',
      'Ride completed',
      'trip-service',
      'settle-1',
    );

    expect(await service.getWallet(driverId)).toMatchObject({
      balanceCentavos: 48_765,
      reservedCentavos: 0,
      availableBalanceCentavos: 48_765,
      lowBalance: false,
    });
    expect((await service.listLedger(driverId, 1, 25)).total).toBe(3);

    let immutableLedgerError: unknown;
    try {
      await db.execute(sql`
        update driver_credit_ledger
        set reason = 'tampered'
        where driver_id = ${driverId}
      `);
    } catch (error) {
      immutableLedgerError = error;
    }
    expect(immutableLedgerError).toBeDefined();
  });

  test('makes an active restriction view-only and blocks new work', async () => {
    await service.updateApproval(
      driverId,
      { status: 'approved', reason: 'Approved for test' },
      'admin_owner',
      'approval-restriction-1',
    );
    expect((await service.updateOnlineStatus(driverId, {
      isOnline: true,
      lat: 7.82,
      lng: 123.43,
    })).isOnline).toBe(true);
    const restriction = await service.createRestriction(
      driverId,
      { reason: 'Safety review required', expiresAt: null },
      'admin_owner',
      'restriction-1',
    );

    const eligibility = await service.checkEligibility(driverId, 0);
    expect(eligibility).toMatchObject({
      eligible: false,
      code: 'ACCOUNT_RESTRICTED',
    });
    expect((await service.listRestrictions(driverId))[0].id).toBe(restriction.id);
    expect((await service.getOperatingStatus(driverId)).driver).toMatchObject({
      id: driverId,
      isOnline: false,
    });
    let blockedError: unknown;
    try {
      await service.updateOnlineStatus(driverId, { isOnline: true });
    } catch (error) {
      blockedError = error;
    }
    expect(blockedError).toMatchObject({ code: 'ACCOUNT_RESTRICTED' });
  });

  test('serializes concurrent top-up approvals and preserves the ₱1,000 cap', async () => {
    const channel = await service.createTopupChannel(
      {
        name: 'Test E-Wallet',
        accountName: 'BaoBao Test',
        accountReference: '09000000001',
        instructions: null,
      },
      'admin_owner',
      'channel-1',
    );
    const first = await service.submitTopup(
      driverId,
      {
        channelId: channel.id,
        amountCentavos: 60_000,
        senderName: 'Test Driver',
        transactionReference: 'REF-ONE',
      },
      'submit-1',
    );
    const second = await service.submitTopup(
      driverId,
      {
        channelId: channel.id,
        amountCentavos: 60_000,
        senderName: 'Test Driver',
        transactionReference: 'REF-TWO',
      },
      'submit-2',
    );

    const approvals = await Promise.allSettled([
      service.reviewTopup(
        first.id,
        'approved',
        'Matched external receipt',
        'admin_owner',
        'approve-1',
      ),
      service.reviewTopup(
        second.id,
        'approved',
        'Matched external receipt',
        'admin_owner',
        'approve-2',
      ),
    ]);
    expect(approvals.filter((result) => result.status === 'fulfilled')).toHaveLength(1);
    const rejected = approvals.find((result) => result.status === 'rejected');
    expect((rejected as PromiseRejectedResult).reason).toBeInstanceOf(DriverDomainError);
    expect((rejected as PromiseRejectedResult).reason.code).toBe('MAX_CREDIT_BALANCE');
    expect((await service.getWallet(driverId)).balanceCentavos).toBe(60_000);
    const topups = await service.listTopups(1, 25);
    expect(topups.items[0]).toHaveProperty('amountCentavos', 60_000);
    expect(topups.items[0]).not.toHaveProperty('request');

    await expect(service.submitTopup(
      driverId,
      {
        channelId: channel.id,
        amountCentavos: 10_000,
        senderName: 'Test Driver',
        transactionReference: ' ref-one ',
      },
      'submit-duplicate',
    )).rejects.toMatchObject({ code: 'DUPLICATE_TOPUP_REFERENCE' });
  });
});

import { beforeEach, describe, expect, test } from 'bun:test';
import { eq, sql } from 'drizzle-orm';
import {
  driverAccountRestrictions,
  drivers,
} from '../../src/db/schema.ts';
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

  test('serializes and reconciles concurrent credit mutations exactly once', async () => {
    const requirement = await service.createDocumentRequirement(
      { name: 'Driver License' },
      'admin_owner',
      'requirement-create-1',
    );
    expect(requirement).toMatchObject({
      isActive: true,
      requiresExpiry: false,
    });
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
    const [adjustment, adjustmentReplay] = await Promise.all([
      service.adjustCredits(
        driverId,
        { amountCentavos: 50_000, reason: 'Test opening balance' },
        'admin_owner',
        'adjustment-1',
      ),
      service.adjustCredits(
        driverId,
        { amountCentavos: 50_000, reason: 'Test opening balance' },
        'admin_owner',
        'adjustment-1',
      ),
    ]);
    expect(adjustmentReplay.ledgerEntry.id).toBe(adjustment.ledgerEntry.id);

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
    const [reservation, replay, refund, refundReplay] = await Promise.all([
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
      service.refundCredits(
        driverId,
        48_000,
        'Controlled integrity-test refund',
        'admin_owner',
        'refund-1',
      ),
      service.refundCredits(
        driverId,
        48_000,
        'Controlled integrity-test refund',
        'admin_owner',
        'refund-1',
      ),
    ]);
    expect(reservation.commissionCentavos).toBe(1_235);
    expect(replay.reservation.id).toBe(reservation.reservation.id);
    expect(refundReplay.ledgerEntry.id).toBe(refund.ledgerEntry.id);
    await expect(service.refundCredits(
      driverId,
      1_000,
      'Would consume reserved commission',
      'admin_owner',
      'refund-2',
    )).rejects.toMatchObject({ code: 'INSUFFICIENT_CREDIT' });

    const settlements = await Promise.all([
      service.transitionReservation(
        'ride_1',
        'settled',
        'Ride completed',
        'trip-service',
        'settle-1',
      ),
      service.transitionReservation(
        'ride_1',
        'settled',
        'Ride completed',
        'trip-service',
        'settle-2',
      ),
    ]);
    expect(settlements[1].id).toBe(settlements[0].id);

    const wallet = await service.getWallet(driverId);
    expect(wallet).toMatchObject({
      balanceCentavos: 765,
      reservedCentavos: 0,
      availableBalanceCentavos: 765,
      lowBalance: true,
    });
    const ledger = await service.listLedger(driverId, 1, 25);
    expect(ledger.total).toBe(4);
    expect(ledger.items.reduce(
      (sum, entry) => sum + entry.balanceDeltaCentavos,
      0,
    )).toBe(wallet.balanceCentavos);
    expect(ledger.items.reduce(
      (sum, entry) => sum + entry.reservedDeltaCentavos,
      0,
    )).toBe(wallet.reservedCentavos);
    expect(ledger.items.filter((entry) => entry.type === 'adjustment')).toHaveLength(1);
    expect(ledger.items.filter((entry) => entry.type === 'refund')).toHaveLength(1);
    expect(ledger.items.filter((entry) => entry.type === 'reserve')).toHaveLength(1);
    expect(ledger.items.filter((entry) => entry.type === 'settle')).toHaveLength(1);

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

  test('persists expiry policy and reevaluates activation without blocking deactivation', async () => {
    await service.updateApproval(
      driverId,
      { status: 'approved', reason: 'Approved for requirement policy test' },
      'admin_owner',
      'approval-requirement-policy-1',
    );
    await service.updateOnlineStatus(driverId, { isOnline: true });

    const requirement = await service.createDocumentRequirement(
      {
        name: 'Franchise Permit',
        isActive: false,
        requiresExpiry: false,
      },
      'admin_owner',
      'requirement-policy-create-1',
    );
    expect(requirement).toMatchObject({
      isActive: false,
      requiresExpiry: false,
    });
    expect((await service.getOperatingStatus(driverId))).toMatchObject({
      canGoOnline: true,
      driver: { isOnline: true },
    });

    const activated = await service.updateDocumentRequirement(
      requirement.id,
      { isActive: true },
      'requirement-policy-activate-1',
    );
    expect(activated).toMatchObject({
      isActive: true,
      requiresExpiry: false,
    });
    expect((await service.getOperatingStatus(driverId))).toMatchObject({
      canGoOnline: false,
      blockingCode: 'DRIVER_DOCUMENTS_INCOMPLETE',
      driver: { isOnline: false },
    });
    await service.reviewDriverDocument(
      driverId,
      requirement.id,
      { status: 'verified', expiresAt: null, notes: 'No expiry required yet' },
      'admin_owner',
      'requirement-policy-review-optional-1',
    );
    await service.updateOnlineStatus(driverId, { isOnline: true });

    const tightened = await service.updateDocumentRequirement(
      requirement.id,
      { requiresExpiry: true },
      'requirement-policy-requires-expiry-1',
    );
    expect(tightened).toMatchObject({
      isActive: true,
      requiresExpiry: true,
    });
    expect((await service.getOperatingStatus(driverId))).toMatchObject({
      canGoOnline: false,
      blockingCode: 'DRIVER_DOCUMENTS_INCOMPLETE',
      driver: { isOnline: false },
    });
    await expect(service.reviewDriverDocument(
      driverId,
      requirement.id,
      { status: 'verified', expiresAt: null, notes: 'Missing expiry' },
      'admin_owner',
      'requirement-policy-review-missing-1',
    )).rejects.toMatchObject({ code: 'INVALID_EXPIRY' });

    await service.reviewDriverDocument(
      driverId,
      requirement.id,
      {
        status: 'verified',
        expiresAt: new Date(Date.now() + 86_400_000).toISOString(),
        notes: 'Expiry checked',
      },
      'admin_owner',
      'requirement-policy-review-valid-1',
    );
    expect((await service.checkEligibility(driverId, 0)).eligible).toBe(true);
    await service.updateOnlineStatus(driverId, { isOnline: true });

    const deactivated = await service.updateDocumentRequirement(
      requirement.id,
      { isActive: false },
      'requirement-policy-deactivate-1',
    );
    expect(deactivated).toMatchObject({
      isActive: false,
      requiresExpiry: true,
    });
    await service.reviewDriverDocument(
      driverId,
      requirement.id,
      { status: 'rejected', expiresAt: null, notes: 'Historical rejection' },
      'admin_owner',
      'requirement-policy-review-inactive-1',
    );
    expect((await service.getOperatingStatus(driverId))).toMatchObject({
      canGoOnline: true,
      driver: { isOnline: true },
    });
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
    expect(await service.getOperatingStatus(driverId)).toMatchObject({
      blockingCode: 'ACCOUNT_RESTRICTED',
      activeRestriction: {
        id: restriction.id,
        reason: 'Safety review required',
      },
      driver: {
        id: driverId,
        isOnline: false,
      },
    });
    expect(await service.getWallet(driverId)).toMatchObject({
      balanceCentavos: 0,
      reservedCentavos: 0,
    });
    expect(await service.listLedger(driverId, 1, 25)).toMatchObject({
      items: [],
      total: 0,
    });
    let blockedError: unknown;
    try {
      await service.updateOnlineStatus(driverId, { isOnline: true });
    } catch (error) {
      blockedError = error;
    }
    expect(blockedError).toMatchObject({ code: 'ACCOUNT_RESTRICTED' });

    await service.liftRestriction(
      restriction.id,
      'Safety review completed',
      'admin_owner',
      'restriction-lift-1',
    );
    expect(await service.checkEligibility(driverId, 0)).toMatchObject({
      eligible: true,
      code: null,
    });
    expect((await service.updateOnlineStatus(
      driverId,
      { isOnline: true },
    )).isOnline).toBe(true);

    const expiring = await service.createRestriction(
      driverId,
      {
        reason: 'Temporary review window',
        expiresAt: new Date(Date.now() + 86_400_000).toISOString(),
      },
      'admin_owner',
      'restriction-expiring-1',
    );
    await db.update(driverAccountRestrictions)
      .set({ expiresAt: new Date(Date.now() - 1_000) })
      .where(eq(driverAccountRestrictions.id, expiring.id));

    expect((await service.listRestrictions(driverId))[0]).toMatchObject({
      id: expiring.id,
      effectiveStatus: 'expired',
    });
    expect(await service.checkEligibility(driverId, 0)).toMatchObject({
      eligible: true,
      code: null,
    });
    expect((await service.updateOnlineStatus(
      driverId,
      { isOnline: true },
    )).isOnline).toBe(true);
  });

  test('reconciles submitted top-ups and serializes every review decision', async () => {
    const channel = await service.createTopupChannel(
      {
        name: 'Test E-Wallet',
        accountName: 'EasyRide Test',
        accountReference: '09000000001',
        instructions: 'Use the transaction reference from the test payment.',
      },
      'admin_owner',
      'channel-1',
    );
    expect(channel).toMatchObject({
      isActive: true,
      createdBy: 'admin_owner',
    });
    expect(await service.listTopupChannels()).toHaveLength(1);

    await expect(service.submitTopup(
      driverId,
      {
        channelId: channel.id,
        amountCentavos: 9_999,
        senderName: 'Test Driver',
        transactionReference: 'BELOW-MINIMUM',
      },
      'submit-below-minimum',
    )).rejects.toMatchObject({ code: 'INVALID_CREDIT_AMOUNT' });

    const duplicateSubmissions = await Promise.allSettled([
      service.submitTopup(
        driverId,
        {
          channelId: channel.id,
          amountCentavos: 10_000,
          senderName: 'Test Driver',
          transactionReference: 'REF ONE',
        },
        'submit-reference-1',
      ),
      service.submitTopup(
        driverId,
        {
          channelId: channel.id,
          amountCentavos: 10_000,
          senderName: 'Test Driver',
          transactionReference: ' refone ',
        },
        'submit-reference-2',
      ),
    ]);
    const submitted = duplicateSubmissions.find(
      (result) => result.status === 'fulfilled',
    ) as PromiseFulfilledResult<Awaited<ReturnType<typeof service.submitTopup>>>;
    const duplicate = duplicateSubmissions.find(
      (result) => result.status === 'rejected',
    ) as PromiseRejectedResult;
    expect(submitted).toBeDefined();
    expect(duplicate.reason).toMatchObject({
      code: 'DUPLICATE_TOPUP_REFERENCE',
    });
    expect((await repository.listDrivers(
      1,
      100,
      undefined,
      new Date('2000-01-01T00:00:00.000Z'),
      new Date('2100-01-01T00:00:00.000Z'),
    )).total).toBe(1);
    expect((await repository.listTopups(
      1,
      100,
      undefined,
      new Date('2100-01-01T00:00:00.000Z'),
    )).total).toBe(0);

    const approvals = await Promise.all([
      service.reviewTopup(
        submitted.value.id,
        'approved',
        'Matched external receipt',
        'admin_owner',
        'approve-retry-1',
      ),
      service.reviewTopup(
        submitted.value.id,
        'approved',
        'Matched external receipt',
        'admin_owner',
        'approve-retry-1',
      ),
    ]);
    expect(approvals[1].request.id).toBe(approvals[0].request.id);
    expect(approvals[0].request).toMatchObject({
      status: 'approved',
      reviewedBy: 'admin_owner',
      reviewReason: 'Matched external receipt',
    });

    const rejectedRequest = await service.submitTopup(
      driverId,
      {
        channelId: channel.id,
        amountCentavos: 10_000,
        senderName: 'Test Driver',
        transactionReference: 'REF-REJECTED',
      },
      'submit-rejected',
    );
    const rejections = await Promise.all([
      service.reviewTopup(
        rejectedRequest.id,
        'rejected',
        'External payment not found',
        'admin_owner',
        'reject-retry-1',
      ),
      service.reviewTopup(
        rejectedRequest.id,
        'rejected',
        'External payment not found',
        'admin_owner',
        'reject-retry-1',
      ),
    ]);
    expect(rejections[1].request.id).toBe(rejections[0].request.id);
    expect(rejections[0].request).toMatchObject({
      status: 'rejected',
      reviewedBy: 'admin_owner',
      reviewReason: 'External payment not found',
    });

    const racedRequest = await service.submitTopup(
      driverId,
      {
        channelId: channel.id,
        amountCentavos: 10_000,
        senderName: 'Test Driver',
        transactionReference: 'REF-RACED',
      },
      'submit-raced',
    );
    const racedReviews = await Promise.allSettled([
      service.reviewTopup(
        racedRequest.id,
        'approved',
        'Approve side of controlled race',
        'admin_owner',
        'approve-race-1',
      ),
      service.reviewTopup(
        racedRequest.id,
        'rejected',
        'Reject side of controlled race',
        'admin_owner',
        'reject-race-1',
      ),
    ]);
    expect(racedReviews.filter(
      (result) => result.status === 'fulfilled',
    )).toHaveLength(1);
    const losingReview = racedReviews.find(
      (result) => result.status === 'rejected',
    ) as PromiseRejectedResult;
    expect(losingReview.reason).toBeInstanceOf(DriverDomainError);
    expect(losingReview.reason).toMatchObject({
      code: 'TOPUP_ALREADY_REVIEWED',
    });

    const balanceBeforeCap = (await service.getWallet(driverId)).balanceCentavos;
    const capRequest = await service.submitTopup(
      driverId,
      {
        channelId: channel.id,
        amountCentavos: 100_000 - balanceBeforeCap,
        senderName: 'Test Driver',
        transactionReference: 'REF-TO-CAP',
      },
      'submit-to-cap',
    );
    await service.reviewTopup(
      capRequest.id,
      'approved',
      'Matched payment up to balance cap',
      'admin_owner',
      'approve-to-cap',
    );
    expect((await service.getWallet(driverId)).balanceCentavos).toBe(100_000);

    const overCapRequest = await service.submitTopup(
      driverId,
      {
        channelId: channel.id,
        amountCentavos: 10_000,
        senderName: 'Test Driver',
        transactionReference: 'REF-OVER-CAP',
      },
      'submit-over-cap',
    );
    await expect(service.reviewTopup(
      overCapRequest.id,
      'approved',
      'Would exceed purchased-credit cap',
      'admin_owner',
      'approve-over-cap',
    )).rejects.toMatchObject({ code: 'MAX_CREDIT_BALANCE' });

    const topups = await service.listTopups(1, 100);
    const driverTopups = await service.listDriverTopups(driverId, 1, 100);
    const ledger = await service.listLedger(driverId, 1, 100);
    const wallet = await service.getWallet(driverId);
    expect(topups.total).toBe(5);
    const approvedTotal = topups.items
      .filter((request) => request.status === 'approved')
      .reduce((sum, request) => sum + request.amountCentavos, 0);
    const ledgerTopupTotal = ledger.items
      .filter((entry) => entry.type === 'topup')
      .reduce((sum, entry) => sum + entry.balanceDeltaCentavos, 0);
    expect(approvedTotal).toBe(100_000);
    expect(ledgerTopupTotal).toBe(approvedTotal);
    expect(wallet.balanceCentavos).toBe(ledgerTopupTotal);
    expect(ledger.items.filter((entry) => entry.type === 'topup')).toHaveLength(
      topups.items.filter((request) => request.status === 'approved').length,
    );
    const retainedApproval = topups.items.find(
      (request) => request.id === submitted.value.id,
    );
    expect(retainedApproval).toMatchObject({
      status: 'approved',
      reviewedBy: 'admin_owner',
      reviewReason: 'Matched external receipt',
    });
    expect(retainedApproval?.reviewedAt).not.toBeNull();
    const retainedRejection = topups.items.find(
      (request) => request.id === rejectedRequest.id,
    );
    expect(retainedRejection).toMatchObject({
      status: 'rejected',
      reviewedBy: 'admin_owner',
      reviewReason: 'External payment not found',
    });
    expect(retainedRejection?.reviewedAt).not.toBeNull();
    expect(topups.items.find(
      (request) => request.id === overCapRequest.id,
    )).toMatchObject({
      status: 'pending',
      reviewedBy: null,
      reviewReason: null,
    });
    expect(driverTopups.total).toBe(topups.total);
    expect(topups.items[0]).not.toHaveProperty('request');
  });
});

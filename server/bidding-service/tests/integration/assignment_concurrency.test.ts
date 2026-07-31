import { beforeEach, describe, expect, test } from 'bun:test';
import {
  bidSessions,
  driverOffers,
} from '../../src/db/schema.ts';
import { BiddingRepositoryImpl } from '../../src/features/repositories/bidding.repository.ts';
import { db } from '../../src/shared/drizzle.ts';

const databaseDescribe = process.env.RUN_BIDDING_ASSIGNMENT_INTEGRATION === '1'
  ? describe
  : describe.skip;

const repository = new BiddingRepositoryImpl();

databaseDescribe('atomic bid-session assignment', () => {
  beforeEach(async () => {
    await db.delete(driverOffers);
    await db.delete(bidSessions);
  });

  test('allows only one normal-or-manual claim for a session', async () => {
    const session = await repository.createSession({
      passengerId: 'passenger-1',
      rideType: 'Bao Shared',
      pickupLatitude: 7.82,
      pickupLongitude: 123.43,
      pickupName: 'Pickup',
      dropoffLatitude: 7.83,
      dropoffLongitude: 123.44,
      dropoffName: 'Dropoff',
      distanceKm: 2,
      durationMinutes: 8,
      offeredFare: 100,
      offeredFareCentavos: 10_000,
      targetDriverId: null,
      expiresAt: new Date(Date.now() + 60_000),
    });
    const [normalOffer, manualOffer] = await Promise.all([
      repository.createOffer(session.id, {
        driverId: 'driver-normal',
        driverName: 'Normal Driver',
        plateNumber: 'NORMAL 1',
        vehicleType: 'BaoBao',
        proposedFare: 100,
        proposedFareCentavos: 10_000,
      }),
      repository.createOffer(session.id, {
        driverId: 'driver-manual',
        driverName: 'Manual Driver',
        plateNumber: 'MANUAL 1',
        vehicleType: 'BaoBao',
        proposedFare: 100,
        proposedFareCentavos: 10_000,
      }),
    ]);

    const claims = await Promise.all([
      repository.claimAssignment({
        sessionId: session.id,
        offerId: normalOffer.id,
        driverId: normalOffer.driverId,
        idempotencyKey: 'normal-claim',
        assignmentSource: 'driver_offer',
      }),
      repository.claimAssignment({
        sessionId: session.id,
        offerId: manualOffer.id,
        driverId: manualOffer.driverId,
        idempotencyKey: 'manual-claim',
        assignmentSource: 'admin',
        assignedByAdminId: 'admin-owner',
      }),
    ]);

    expect(claims.filter((claim) => claim.state === 'claimed')).toHaveLength(1);
    expect(claims.filter((claim) => claim.state === 'conflict')).toHaveLength(1);
    const stored = await repository.findSessionById(session.id);
    expect(stored?.status).toBe('assigning');
    expect([
      normalOffer.driverId,
      manualOffer.driverId,
    ].includes(stored?.acceptedDriverId ?? '')).toBe(true);
  });
});

import { beforeEach, describe, expect, test } from 'bun:test';
import { sql } from 'drizzle-orm';
import {
  passengerRestrictions,
  passengers,
} from '../../src/db/schema.ts';
import { PassengerRepositoryImpl } from '../../src/features/repositories/passenger.repository.ts';
import { PassengerService } from '../../src/features/services/passenger.service.ts';
import { db } from '../../src/shared/drizzle.ts';

const databaseDescribe = process.env.RUN_PASSENGER_RESTRICTION_INTEGRATION === '1'
  ? describe
  : describe.skip;

databaseDescribe('Passenger restriction idempotency', () => {
  const passengerId = 'passenger-restriction-test';
  const service = new PassengerService(new PassengerRepositoryImpl());

  beforeEach(async () => {
    await db.execute(sql`
      truncate table passenger_restrictions, ride_requests, passengers
      restart identity cascade
    `);
    await db.insert(passengers).values({
      id: passengerId,
      name: 'Restriction Test Passenger',
      email: 'restriction-passenger@test.local',
      phone: '09000000000',
      passwordHash: 'not-a-real-password',
      isVerified: true,
    });
  });

  test('serializes concurrent create and lift retries and rejects key reuse', async () => {
    const createInput = {
      passengerId,
      reason: 'Account review',
      createdBy: 'admin-1',
      idempotencyKey: 'create-same-key',
    };
    const [firstCreate, secondCreate] = await Promise.all([
      service.restrictPassenger(createInput),
      service.restrictPassenger(createInput),
    ]);
    expect(firstCreate.id).toBe(secondCreate.id);

    const conflictingCreates = await Promise.allSettled([
      service.restrictPassenger({
        ...createInput,
        reason: 'First concurrent reason',
        idempotencyKey: 'create-conflict-key',
      }),
      service.restrictPassenger({
        ...createInput,
        reason: 'Second concurrent reason',
        idempotencyKey: 'create-conflict-key',
      }),
    ]);
    expect(conflictingCreates.filter((result) => result.status === 'fulfilled')).toHaveLength(1);
    expect(conflictingCreates.filter((result) => result.status === 'rejected')).toHaveLength(1);

    const liftInput = {
      restrictionId: firstCreate.id,
      reason: 'Review complete',
      adminId: 'admin-1',
      idempotencyKey: 'lift-same-key',
    };
    const [firstLift, secondLift] = await Promise.all([
      service.liftPassengerRestriction(liftInput),
      service.liftPassengerRestriction(liftInput),
    ]);
    expect(firstLift.revokedAt).toEqual(secondLift.revokedAt);

    await expect(service.liftPassengerRestriction({
      ...liftInput,
      reason: 'Different lift reason',
    })).rejects.toMatchObject({
      status: 409,
      message: 'IDEMPOTENCY_KEY_REUSED',
    });

    const competingTarget = await service.restrictPassenger({
      ...createInput,
      idempotencyKey: 'create-competing-lift',
    });
    const competingLifts = await Promise.allSettled([
      service.liftPassengerRestriction({
        restrictionId: competingTarget.id,
        reason: 'First lift',
        adminId: 'admin-1',
        idempotencyKey: 'first-lift-key',
      }),
      service.liftPassengerRestriction({
        restrictionId: competingTarget.id,
        reason: 'Second lift',
        adminId: 'admin-2',
        idempotencyKey: 'second-lift-key',
      }),
    ]);
    expect(competingLifts.filter((result) => result.status === 'fulfilled')).toHaveLength(1);
    expect(competingLifts.filter((result) => result.status === 'rejected')).toHaveLength(1);

    const rows = await db.select().from(passengerRestrictions);
    expect(rows).toHaveLength(3);
    expect(rows.find((row) => row.id === firstCreate.id)).toMatchObject({
      createdBy: 'admin-1',
      liftedBy: 'admin-1',
      liftReason: 'Review complete',
      liftIdempotencyKey: 'lift-same-key',
    });
  });
});

import { describe, expect, test } from 'bun:test';
import { Hono } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { PassengerRepository } from '../../src/features/entities/passenger.types.ts';
import {
  requireAdminActorHeader,
  RestrictPassengerSchema,
} from '../../src/features/schemas/passenger.schema.ts';
import { PassengerService } from '../../src/features/services/passenger.service.ts';
import { globalErrorHandler } from '../../src/shared/middleware/error.ts';

const rideRequest = {
  passenger_id: 'passenger-1',
  ride_type: 'solo-ride' as const,
  pickup_latitude: 7.82,
  pickup_longitude: 123.43,
  pickup_name: 'Pickup',
  dropoff_latitude: 7.83,
  dropoff_longitude: 123.44,
  dropoff_name: 'Dropoff',
  fare: 100,
};

function repository(restriction: { id: string; reason: string; endsAt: Date | null } | null) {
  let created = false;
  return {
    created: () => created,
    implementation: {
      findActiveRestriction: async () => restriction,
      registerRideRequest: async (input: typeof rideRequest) => {
        created = true;
        return {
          id: 'ride-1',
          ...input,
          status: 'requested',
          created_at: new Date(),
        };
      },
    } as unknown as PassengerRepository,
  };
}

describe('Passenger restriction enforcement', () => {
  test.each([
    ['indefinite', null],
    ['temporary', new Date(Date.now() + 60_000)],
  ])('blocks ride creation for an active %s restriction', async (_label, endsAt) => {
    const fake = repository({
      id: 'restriction-1',
      reason: 'Account review',
      endsAt,
    });
    const service = new PassengerService(fake.implementation);

    let thrown: unknown;
    try {
      await service.createRideRequest(rideRequest);
    } catch (error) {
      thrown = error;
    }

    expect(thrown).toBeInstanceOf(HTTPException);
    expect((thrown as HTTPException).status).toBe(403);
    expect((thrown as Error).message).toBe('ACCOUNT_RESTRICTED');
    expect(fake.created()).toBe(false);
  });

  test('allows ride creation after a restriction is expired or lifted', async () => {
    const fake = repository(null);
    const service = new PassengerService(fake.implementation);

    const result = await service.createRideRequest(rideRequest);

    expect(result.id).toBe('ride-1');
    expect(fake.created()).toBe(true);
  });

  test('returns the stable public restriction code', async () => {
    const app = new Hono();
    app.onError(globalErrorHandler);
    app.get('/', () => {
      throw new HTTPException(403, { message: 'ACCOUNT_RESTRICTED' });
    });

    const response = await app.request('/');

    expect(response.status).toBe(403);
    expect(await response.json()).toMatchObject({
      code: 'ACCOUNT_RESTRICTED',
      message: 'ACCOUNT_RESTRICTED',
    });
  });

  test('requires the trusted Admin actor header and ignores a body actor', () => {
    for (const invalidActor of [undefined, '   ', 'a'.repeat(129)]) {
      let thrown: unknown;
      try {
        requireAdminActorHeader(invalidActor);
      } catch (error) {
        thrown = error;
      }
      expect(thrown).toMatchObject({
        status: 422,
        message: 'INVALID_ADMIN_ACTOR',
      });
    }
    expect(requireAdminActorHeader(' admin-1 ')).toBe('admin-1');

    const payload = RestrictPassengerSchema.parse({
      reason: 'Account review',
      admin_id: 'spoofed-admin',
    });
    expect('admin_id' in payload).toBe(false);
  });

  test('binds create and lift idempotency keys to their payloads', async () => {
    let createHash: string | undefined;
    let liftHash: string | undefined;
    const implementation = {
      retrievePassengerProfile: async () => ({
        id: 'passenger-1',
        name: 'Passenger',
        email: 'passenger@example.com',
        phone: '09123456789',
        preferred_ride_type: null,
        created_at: new Date(),
        password_hash: 'hash',
        is_verified: true,
      }),
      createRestriction: async (input: any) => {
        if (createHash && createHash !== input.requestHash) {
          throw new Error('IDEMPOTENCY_KEY_REUSED');
        }
        createHash = input.requestHash;
        return {
          id: 'restriction-1',
          passengerId: input.passengerId,
          reason: input.reason,
          endsAt: input.endsAt ?? null,
        };
      },
      revokeRestriction: async (input: any) => {
        if (liftHash && liftHash !== input.requestHash) {
          throw new Error('IDEMPOTENCY_KEY_REUSED');
        }
        liftHash = input.requestHash;
        return {
          id: input.restrictionId,
          passengerId: 'passenger-1',
          reason: 'Account review',
          endsAt: null,
          revokedAt: new Date(),
        };
      },
    } as unknown as PassengerRepository;
    const service = new PassengerService(implementation);
    const create = {
      passengerId: 'passenger-1',
      reason: 'Account review',
      createdBy: 'admin-1',
      idempotencyKey: 'create-key',
    };
    await service.restrictPassenger(create);
    await service.restrictPassenger(create);
    await expect(service.restrictPassenger({
      ...create,
      reason: 'Different review',
    })).rejects.toMatchObject({
      status: 409,
      message: 'IDEMPOTENCY_KEY_REUSED',
    });

    const lift = {
      restrictionId: 'restriction-1',
      reason: 'Review complete',
      adminId: 'admin-1',
      idempotencyKey: 'lift-key',
    };
    await service.liftPassengerRestriction(lift);
    await service.liftPassengerRestriction(lift);
    await expect(service.liftPassengerRestriction({
      ...lift,
      adminId: 'admin-2',
    })).rejects.toMatchObject({
      status: 409,
      message: 'IDEMPOTENCY_KEY_REUSED',
    });
  });
});

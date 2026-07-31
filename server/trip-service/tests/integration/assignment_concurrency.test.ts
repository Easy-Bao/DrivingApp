import { beforeEach, describe, expect, test } from 'bun:test';
import { rides } from '../../src/db/schema.ts';
import { RideRepositoryImpl } from '../../src/features/repositories/ride.repository.ts';
import { db } from '../../src/shared/drizzle.ts';

const databaseDescribe = process.env.RUN_TRIP_ASSIGNMENT_INTEGRATION === '1'
  ? describe
  : describe.skip;

const repository = new RideRepositoryImpl();

async function createRide(index: number, rideType: string) {
  return await repository.createRide({
    passenger_id: `passenger-${index}`,
    passenger_name: `Passenger ${index}`,
    ride_type: rideType,
    pickup_latitude: 7.82,
    pickup_longitude: 123.43,
    pickup_name: 'Pickup',
    dropoff_latitude: 7.83,
    dropoff_longitude: 123.44,
    dropoff_name: 'Dropoff',
    fare: 100,
    fare_centavos: 10_000,
  });
}

function assignment(
  driverId: string,
  source: 'driver_offer' | 'admin' = 'driver_offer',
) {
  return {
    driver_id: driverId,
    driver_name: 'Test Driver',
    driver_rating: '4.9',
    vehicle_type: 'BaoBao',
    plate_number: 'TEST 001',
    commission_rate_basis_points: 1_000,
    commission_centavos: 1_000,
    credit_reservation_id: crypto.randomUUID(),
    assignment_source: source,
    assigned_by_admin_id: source === 'admin' ? 'admin-owner' : null,
  };
}

databaseDescribe('atomic Driver assignment', () => {
  beforeEach(async () => {
    await db.delete(rides);
  });

  test('allows only one concurrent Premium assignment for the same Driver', async () => {
    const [normalRide, manualRide] = await Promise.all([
      createRide(1, 'Bao Premium'),
      createRide(2, 'Bao Premium'),
    ]);

    const results = await Promise.allSettled([
      repository.acceptRideTransaction(
        normalRide.id,
        assignment('driver-1', 'driver_offer'),
      ),
      repository.acceptRideTransaction(
        manualRide.id,
        assignment('driver-1', 'admin'),
      ),
    ]);

    expect(results.filter((result) => result.status === 'fulfilled')).toHaveLength(1);
    expect(results.filter((result) => result.status === 'rejected')).toHaveLength(1);
    const stored = await db.select().from(rides);
    expect(stored.filter((ride) => ride.status === 'accepted')).toHaveLength(1);
    expect(stored.filter((ride) => ride.status === 'requested')).toHaveLength(1);
  });

  test('never exceeds the existing five-Shared-ride capacity under concurrency', async () => {
    const requested = await Promise.all(
      Array.from({ length: 6 }, (_, index) => createRide(index, 'Bao Shared')),
    );

    const results = await Promise.allSettled(
      requested.map((ride) => repository.acceptRideTransaction(
        ride.id,
        assignment('driver-1'),
      )),
    );

    expect(results.filter((result) => result.status === 'fulfilled')).toHaveLength(5);
    expect(results.filter((result) => result.status === 'rejected')).toHaveLength(1);
    const stored = await db.select().from(rides);
    expect(stored.filter((ride) => ride.status === 'accepted')).toHaveLength(5);
    expect(stored.filter((ride) => ride.status === 'requested')).toHaveLength(1);
  });
});

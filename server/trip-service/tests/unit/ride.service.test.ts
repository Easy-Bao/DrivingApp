import { afterEach, beforeEach, describe, expect, test } from 'bun:test';
import { RideService } from '../../src/features/services/ride.service.ts';

const originalFetch = globalThis.fetch;

function requestedRide(overrides: Record<string, unknown> = {}) {
  return {
    id: 'ride-1',
    passengerId: 'passenger-1',
    passengerName: 'Passenger',
    rideType: 'solo-ride',
    pickupLatitude: 7.82,
    pickupLongitude: 123.43,
    pickupName: 'Pickup',
    dropoffLatitude: 7.83,
    dropoffLongitude: 123.44,
    dropoffName: 'Dropoff',
    fare: 150,
    fareCentavos: 15000,
    commissionRateBasisPoints: null,
    commissionCentavos: null,
    creditReservationId: null,
    assignmentSource: 'driver_offer',
    assignedByAdminId: null,
    paymentStatus: 'cash_pending',
    pendingStatus: null,
    statusRequestId: null,
    statusTransitionStartedAt: null,
    status: 'requested',
    createdAt: new Date(),
    updatedAt: new Date(),
    completedAt: null,
    driverId: null,
    driverName: null,
    driverRating: null,
    vehicleType: null,
    plateNumber: null,
    ...overrides,
  };
}

function repository(ride = requestedRide()) {
  return {
    createRide: async (details: Record<string, unknown>) => requestedRide({
      passengerId: details.passenger_id,
      passengerName: details.passenger_name,
    }),
    findRideById: async () => ride,
    findActiveRides: async () => [],
    findRidesByDriverId: async () => [],
    findRidesByPassengerId: async () => [],
    acceptRideTransaction: async (_id: string, input: Record<string, unknown>) => ({
      ...ride,
      status: 'accepted',
      driverId: input.driver_id,
      driverName: input.driver_name,
      commissionRateBasisPoints: input.commission_rate_basis_points,
      commissionCentavos: input.commission_centavos,
      creditReservationId: input.credit_reservation_id,
    }),
    beginStatusTransition: async (_id: string, status: string, requestId: string) => ({
      ...ride,
      pendingStatus: status,
      statusRequestId: requestId,
    }),
    completeStatusTransition: async (_id: string, status: string) => ({ ...ride, status }),
    findPendingStatusTransitions: async () => [],
    findRidesForReport: async () => [],
  };
}

beforeEach(() => {
  process.env.PASSENGER_SERVICE_URL = 'http://passenger-service:8081';
  process.env.DRIVER_SERVICE_URL = 'http://driver-service:8082';
  process.env.ADMIN_SERVICE_URL = 'http://admin-service:8089';
  process.env.FARE_SERVICE_URL = 'http://fare-service:8087';
  process.env.INTERNAL_SERVICE_TOKEN = 'test-internal-token';
});

afterEach(() => {
  globalThis.fetch = originalFetch;
});

describe('RideService safety workflow', () => {
  test('checks passenger and both service zones before creating a ride', async () => {
    const calls: string[] = [];
    globalThis.fetch = (async (input) => {
      const url = String(input);
      calls.push(url);
      if (url.includes('/ride-access')) {
        return Response.json({ allowed: true });
      }
      if (url.includes('/zones/check')) {
        return Response.json({ allowed: true });
      }
      return Response.json({ 'passenger-1': { name: 'Test Passenger' } });
    }) as typeof fetch;

    const service = new RideService(repository() as any);
    const created = await service.createRideRequest({
      passenger_id: 'passenger-1',
      pickup_latitude: 7.82,
      pickup_longitude: 123.43,
      dropoff_latitude: 7.83,
      dropoff_longitude: 123.44,
      fare: 150,
    });

    expect(calls.some((url) => url.includes('/ride-access'))).toBe(true);
    expect(calls.some((url) => url.includes('/zones/check'))).toBe(true);
    expect(created.passengerName).toBe('Test Passenger');
  });

  test('reserves the snapshotted commission using the canonical driver profile', async () => {
    globalThis.fetch = (async (input) => {
      const url = String(input);
      if (url.includes('/profile')) {
        return Response.json({
          id: 'driver-1',
          name: 'Canonical Driver',
          rating: 4.9,
          vehicleType: 'BaoBao',
          plateNumber: 'BAO 100',
        });
      }
      if (url.includes('/pricing/commission')) {
        return Response.json({ rate_basis_points: 1000 });
      }
      if (url.includes('/credits/reservations')) {
        return Response.json({
          reservation: { id: 'reservation-1', commissionCentavos: 1500 },
          commissionCentavos: 1500,
        });
      }
      if (url.includes('/fares/internal/transactions')) {
        return Response.json({ rideId: 'ride-1' });
      }
      throw new Error(`Unexpected request: ${url}`);
    }) as typeof fetch;

    const service = new RideService(repository() as any);
    const accepted = await service.acceptRideRequest(
      'ride-1',
      { driver_id: 'driver-1' },
      'accept-key',
    );

    expect(accepted.driverName).toBe('Canonical Driver');
    expect(accepted.commissionRateBasisPoints).toBe(1000);
    expect(accepted.commissionCentavos).toBe(1500);
    expect(accepted.creditReservationId).toBe('reservation-1');
  });

  test('releases a reservation if the trip assignment commit fails', async () => {
    const calls: string[] = [];
    globalThis.fetch = (async (input) => {
      const url = String(input);
      calls.push(url);
      if (url.includes('/profile')) {
        return Response.json({ id: 'driver-1', name: 'Driver' });
      }
      if (url.includes('/pricing/commission')) {
        return Response.json({ rate_basis_points: 1000 });
      }
      if (url.endsWith('/credits/reservations')) {
        return Response.json({
          reservation: { id: 'reservation-1', commissionCentavos: 1500 },
          commissionCentavos: 1500,
        });
      }
      if (url.includes('/fares/internal/transactions')) {
        return Response.json({ rideId: 'ride-1' });
      }
      if (url.includes('/release')) {
        return Response.json({ status: 'released' });
      }
      throw new Error(`Unexpected request: ${url}`);
    }) as typeof fetch;
    const failingRepository = {
      ...repository(),
      acceptRideTransaction: async () => {
        throw new Error('Ride already accepted');
      },
    };

    const service = new RideService(failingRepository as any);
    await expect(service.acceptRideRequest(
      'ride-1',
      { driver_id: 'driver-1' },
      'accept-key',
    )).rejects.toThrow();
    expect(calls.some((url) => url.includes('/release'))).toBe(true);
  });

  test('retains and safely retries a pending settlement after a local commit failure', async () => {
    let current: any = requestedRide({
      status: 'in_transit',
      driverId: 'driver-1',
      creditReservationId: 'reservation-1',
    });
    let completeAttempts = 0;
    const downstreamKeys: string[] = [];
    globalThis.fetch = (async (input, init) => {
      downstreamKeys.push(new Headers(init?.headers).get('Idempotency-Key') ?? '');
      return Response.json({ status: 'ok' });
    }) as typeof fetch;
    const pendingRepository = {
      ...repository(current),
      findRideById: async () => current,
      beginStatusTransition: async (_id: string, status: string, requestId: string) => {
        current = {
          ...current,
          pendingStatus: status,
          statusRequestId: requestId,
          statusTransitionStartedAt: new Date(),
        };
        return current;
      },
      completeStatusTransition: async (_id: string, status: string) => {
        completeAttempts += 1;
        if (completeAttempts === 1) throw new Error('database unavailable');
        current = {
          ...current,
          status,
          pendingStatus: null,
          statusRequestId: null,
          statusTransitionStartedAt: null,
        };
        return current;
      },
      findPendingStatusTransitions: async () => [current],
    };
    const service = new RideService(pendingRepository as any);

    await expect(service.updateRideStatus(
      'ride-1',
      'completed',
      'original-status-key',
    )).rejects.toThrow('database unavailable');
    expect(current.pendingStatus).toBe('completed');

    const completed = await service.updateRideStatus(
      'ride-1',
      'completed',
      'different-retry-key',
    );
    expect(completed.status).toBe('completed');
    expect(new Set(downstreamKeys)).toEqual(new Set([
      'original-status-key:settle',
      'original-status-key:fare-status',
    ]));
  });
});

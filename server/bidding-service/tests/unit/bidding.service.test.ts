import { describe, expect, test } from 'bun:test';
import { HTTPException } from 'hono/http-exception';
import { ServiceClientError } from '../../src/features/clients/bidding.clients.ts';
import {
  BidSession,
  BiddingRepository,
  DriverOffer,
} from '../../src/features/entities/bidding.types.ts';
import {
  BiddingService,
  BiddingServiceClients,
} from '../../src/features/services/bidding.service.ts';

function session(overrides: Partial<BidSession> = {}): BidSession {
  const now = new Date();
  return {
    id: 'session-1',
    passengerId: 'passenger-real',
    rideType: 'Solo Ride',
    pickupLatitude: 7.82,
    pickupLongitude: 123.43,
    pickupName: 'Pickup',
    dropoffLatitude: 7.83,
    dropoffLongitude: 123.44,
    dropoffName: 'Dropoff',
    distanceKm: 5,
    durationMinutes: 10,
    offeredFare: 92.5,
    offeredFareCentavos: 9_250,
    status: 'open',
    acceptedDriverId: null,
    acceptedOfferId: null,
    acceptedTripId: null,
    acceptanceIdempotencyKey: null,
    assignmentSource: null,
    assignedByAdminId: null,
    targetDriverId: null,
    createdAt: now,
    updatedAt: now,
    expiresAt: new Date(now.getTime() + 60_000),
    ...overrides,
  };
}

function offer(overrides: Partial<DriverOffer> = {}): DriverOffer {
  return {
    id: 'offer-1',
    sessionId: 'session-1',
    driverId: 'driver-real',
    driverName: 'Canonical Driver',
    plateNumber: 'BAO 123',
    vehicleType: 'BaoBao',
    proposedFare: 95,
    proposedFareCentavos: 9_500,
    status: 'pending',
    createdAt: new Date(),
    ...overrides,
  };
}

function clients(
  overrides: Partial<BiddingServiceClients> = {},
): BiddingServiceClients {
  return {
    passengerClient: {
      checkRideAccess: async () => undefined,
      fetchPassengersBatch: async () => ({}),
    },
    adminClient: {
      checkZones: async () => undefined,
      currentCommission: async () => 1_000,
    },
    fareClient: {
      estimateFare: async () => ({
        amount: 92.5,
        estimate: { totalFare: 92.5, total_fare: 92.5 },
      }),
    },
    driverClient: {
      fetchProfile: async () => ({
        id: 'driver-real',
        name: 'Canonical Driver',
        plateNumber: 'BAO 123',
        vehicleType: 'BaoBao',
      }),
      checkEligibility: async (_driverId, requiredCommissionCentavos) => ({
        eligible: true,
        code: null,
        message: null,
        availableBalanceCentavos: 100_000,
        requiredCommissionCentavos,
      }),
    },
    tripClient: {
      fetchDriverActiveRides: async () => [],
      createRide: async () => ({ id: 'trip-1' }),
      acceptRide: async () => undefined,
      cancelRide: async () => undefined,
    },
    ...overrides,
  };
}

describe('BiddingService trust and assignment boundaries', () => {
  test('blocks new bidding mutations while the passenger is restricted', async () => {
    const mutations: string[] = [];
    const repository = {
      createSession: async () => {
        mutations.push('create-session');
        return session();
      },
      findSessionById: async () => session(),
      findSessionWithOffers: async () => ({
        ...session(),
        offers: [offer()],
      }),
      findPendingOffer: async () => null,
      createOffer: async () => {
        mutations.push('create-offer');
        return offer();
      },
      claimAssignment: async () => {
        mutations.push('claim-assignment');
        return { state: 'claimed' as const, session: session({ status: 'assigning' }) };
      },
    } as unknown as BiddingRepository;
    const service = new BiddingService(repository, clients({
      passengerClient: {
        checkRideAccess: async () => {
          throw new ServiceClientError(
            'passenger',
            403,
            'ACCOUNT_RESTRICTED',
            'ACCOUNT_RESTRICTED',
          );
        },
        fetchPassengersBatch: async () => ({}),
      },
    }));
    const operations = [
      () => service.createSession({
        ride_type: 'Solo Ride',
        pickup_latitude: 7.82,
        pickup_longitude: 123.43,
        dropoff_latitude: 7.83,
        dropoff_longitude: 123.44,
        distance_km: 5,
        duration_minutes: 10,
      }, 'passenger-real'),
      () => service.placeOffer('session-1', 'driver-real', {}),
      () => service.acceptOffer('session-1', 'offer-1', 'passenger-real'),
      () => service.manualAssign('session-1', 'driver-real', 'admin-1', 'manual-1'),
    ];

    for (const operation of operations) {
      let thrown: unknown;
      try {
        await operation();
      } catch (error) {
        thrown = error;
      }
      expect(thrown).toMatchObject({
        status: 403,
        message: 'ACCOUNT_RESTRICTED',
      });
    }
    expect(mutations).toEqual([]);
  });

  test('uses JWT passenger identity and the fare-service snapshot', async () => {
    let created: Record<string, unknown> | undefined;
    const repository = {
      createSession: async (input: Record<string, unknown>) => {
        created = input;
        return session({
          passengerId: String(input.passengerId),
          offeredFare: Number(input.offeredFare),
          offeredFareCentavos: Number(input.offeredFareCentavos),
        });
      },
    } as unknown as BiddingRepository;
    const service = new BiddingService(repository, clients());

    await service.createSession({
      passenger_id: 'passenger-spoofed',
      ride_type: 'Solo Ride',
      pickup_latitude: 7.82,
      pickup_longitude: 123.43,
      dropoff_latitude: 7.83,
      dropoff_longitude: 123.44,
      distance_km: 5,
      duration_minutes: 10,
    }, 'passenger-real');

    expect(created?.passengerId).toBe('passenger-real');
    expect(created?.offeredFare).toBe(92.5);
    expect(created?.offeredFareCentavos).toBe(9_250);
  });

  test('persists only canonical driver profile data on an offer', async () => {
    let created: Record<string, unknown> | undefined;
    const repository = {
      findSessionById: async () => session(),
      findPendingOffer: async () => null,
      createOffer: async (_sessionId: string, input: Record<string, unknown>) => {
        created = input;
        return offer({
          driverName: String(input.driverName),
          plateNumber: String(input.plateNumber),
        });
      },
    } as unknown as BiddingRepository;
    const service = new BiddingService(repository, clients());

    await service.placeOffer('session-1', 'driver-real', { proposed_fare: 95 });

    expect(created).toMatchObject({
      driverId: 'driver-real',
      driverName: 'Canonical Driver',
      plateNumber: 'BAO 123',
      proposedFare: 95,
    });
  });

  test('accepts the remote trip before completing local bid state', async () => {
    const events: string[] = [];
    const winningOffer = offer();
    const assigning = session({
      status: 'assigning',
      acceptedDriverId: winningOffer.driverId,
      acceptedOfferId: winningOffer.id,
      acceptanceIdempotencyKey: 'passenger:session-1:offer:offer-1',
      assignmentSource: 'driver_offer',
    });
    const repository = {
      findSessionWithOffers: async () => ({
        ...session(),
        offers: [winningOffer],
      }),
      claimAssignment: async () => {
        events.push('claim');
        return { state: 'claimed' as const, session: assigning };
      },
      recordAssignmentTrip: async () => {
        events.push('record-trip');
        return { ...assigning, acceptedTripId: 'trip-1' };
      },
      completeAssignment: async () => {
        events.push('complete-local');
        return {
          session: {
            ...assigning,
            status: 'accepted',
            acceptedTripId: 'trip-1',
          },
          offer: { ...winningOffer, status: 'accepted' },
        };
      },
    } as unknown as BiddingRepository;
    const service = new BiddingService(repository, clients({
      tripClient: {
        fetchDriverActiveRides: async () => [],
        createRide: async () => {
          events.push('create-trip');
          return { id: 'trip-1' };
        },
        acceptRide: async () => {
          events.push('reserve-and-accept-trip');
        },
        cancelRide: async () => undefined,
      },
    }));

    const result = await service.acceptOffer(
      'session-1',
      'offer-1',
      'passenger-real',
    );

    expect(events).toEqual([
      'claim',
      'create-trip',
      'record-trip',
      'reserve-and-accept-trip',
      'complete-local',
    ]);
    expect(result.rideId).toBe('trip-1');
  });

  test('cancels the trip and releases the claim when credit reservation fails', async () => {
    const events: string[] = [];
    const winningOffer = offer();
    const assigning = session({
      status: 'assigning',
      acceptedDriverId: winningOffer.driverId,
      acceptedOfferId: winningOffer.id,
      acceptanceIdempotencyKey: 'passenger:session-1:offer:offer-1',
      assignmentSource: 'driver_offer',
    });
    const repository = {
      findSessionWithOffers: async () => ({
        ...session(),
        offers: [winningOffer],
      }),
      claimAssignment: async () => ({ state: 'claimed' as const, session: assigning }),
      recordAssignmentTrip: async () => ({ ...assigning, acceptedTripId: 'trip-1' }),
      findSessionById: async () => ({ ...assigning, acceptedTripId: 'trip-1' }),
      releaseAssignment: async () => {
        events.push('release-local');
      },
    } as unknown as BiddingRepository;
    const service = new BiddingService(repository, clients({
      tripClient: {
        fetchDriverActiveRides: async () => [],
        createRide: async () => ({ id: 'trip-1' }),
        acceptRide: async () => {
          throw new ServiceClientError(
            'trip',
            409,
            'INSUFFICIENT_CREDIT',
            'INSUFFICIENT_CREDIT',
          );
        },
        cancelRide: async () => {
          events.push('cancel-trip');
        },
      },
    }));

    let thrown: unknown;
    try {
      await service.acceptOffer('session-1', 'offer-1', 'passenger-real');
    } catch (error) {
      thrown = error;
    }

    expect(thrown).toBeInstanceOf(HTTPException);
    expect((thrown as HTTPException).status).toBe(409);
    expect(events).toEqual(['cancel-trip', 'release-local']);
  });

  test('manual assignment uses the session fare and the same guarded trip path', async () => {
    let offeredFare: number | undefined;
    let tripPayload: Record<string, unknown> | undefined;
    let acceptedSource: string | undefined;
    const repository = {
      findSessionWithOffers: async () => ({ ...session(), offers: [] }),
      createOffer: async (_sessionId: string, input: Record<string, unknown>) => {
        offeredFare = Number(input.proposedFare);
        return offer({
          proposedFare: offeredFare,
          proposedFareCentavos: Number(input.proposedFareCentavos),
        });
      },
      claimAssignment: async (input: Record<string, unknown>) => ({
        state: 'claimed' as const,
        session: session({
          status: 'assigning',
          acceptedDriverId: String(input.driverId),
          acceptedOfferId: String(input.offerId),
          acceptanceIdempotencyKey: String(input.idempotencyKey),
          assignmentSource: 'admin',
          assignedByAdminId: String(input.assignedByAdminId),
        }),
      }),
      recordAssignmentTrip: async () => session({
        status: 'assigning',
        acceptedDriverId: 'driver-real',
        acceptedOfferId: 'offer-1',
        acceptedTripId: 'trip-1',
        acceptanceIdempotencyKey: 'manual-1',
        assignmentSource: 'admin',
        assignedByAdminId: 'admin-1',
      }),
      completeAssignment: async () => ({
        session: session({
          status: 'accepted',
          acceptedDriverId: 'driver-real',
          acceptedOfferId: 'offer-1',
          acceptedTripId: 'trip-1',
          acceptanceIdempotencyKey: 'manual-1',
          assignmentSource: 'admin',
          assignedByAdminId: 'admin-1',
        }),
        offer: offer({
          status: 'accepted',
          proposedFare: 92.5,
          proposedFareCentavos: 9_250,
        }),
      }),
      findSessionById: async () => session(),
      updateOfferStatus: async () => offer({ status: 'rejected' }),
    } as unknown as BiddingRepository;
    const service = new BiddingService(repository, clients({
      tripClient: {
        fetchDriverActiveRides: async () => [],
        createRide: async (payload) => {
          tripPayload = payload;
          return { id: 'trip-1' };
        },
        acceptRide: async (_rideId, input) => {
          acceptedSource = input.assignmentSource;
        },
        cancelRide: async () => undefined,
      },
    }));

    const result = await service.manualAssign(
      'session-1',
      'driver-real',
      'admin-1',
      'manual-1',
    );

    expect(offeredFare).toBe(92.5);
    expect(tripPayload?.fare).toBe(92.5);
    expect(tripPayload?.assigned_by_admin_id).toBe('admin-1');
    expect(acceptedSource).toBe('admin');
    expect(result.rideId).toBe('trip-1');
  });

  test('a concurrent idempotent completion never cancels the winning trip', async () => {
    let detailReads = 0;
    let canceled = false;
    const winningOffer = offer();
    const key = 'passenger:session-1:offer:offer-1';
    const accepted = session({
      status: 'accepted',
      acceptedDriverId: 'driver-real',
      acceptedOfferId: 'offer-1',
      acceptedTripId: 'trip-1',
      acceptanceIdempotencyKey: key,
      assignmentSource: 'driver_offer',
    });
    const repository = {
      findSessionWithOffers: async () => {
        detailReads += 1;
        return {
          ...(detailReads === 1 ? session() : accepted),
          offers: [{ ...winningOffer, status: detailReads === 1 ? 'pending' : 'accepted' }],
        };
      },
      claimAssignment: async () => ({
        state: 'claimed' as const,
        session: session({
          status: 'assigning',
          acceptedDriverId: 'driver-real',
          acceptedOfferId: 'offer-1',
          acceptanceIdempotencyKey: key,
          assignmentSource: 'driver_offer',
        }),
      }),
      recordAssignmentTrip: async () => ({ ...accepted, status: 'assigning' }),
      completeAssignment: async () => {
        throw new Error('concurrent completion');
      },
      findSessionById: async () => accepted,
    } as unknown as BiddingRepository;
    const service = new BiddingService(repository, clients({
      tripClient: {
        fetchDriverActiveRides: async () => [],
        createRide: async () => ({ id: 'trip-1' }),
        acceptRide: async () => undefined,
        cancelRide: async () => {
          canceled = true;
        },
      },
    }));

    const result = await service.acceptOffer(
      'session-1',
      'offer-1',
      'passenger-real',
    );

    expect(result.rideId).toBe('trip-1');
    expect(canceled).toBe(false);
  });
});

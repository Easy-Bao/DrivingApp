import { Logger } from '../../shared/logger/logger.ts';

type ErrorBody = {
  code?: string;
  message?: string;
  error?: string | {
    code?: string;
    message?: string;
  };
};

export class ServiceClientError extends Error {
  constructor(
    public readonly service: string,
    public readonly status: number,
    public readonly code: string,
    message: string,
  ) {
    super(message);
    this.name = 'ServiceClientError';
  }
}

function internalHeaders(extra: Record<string, string> = {}) {
  const token = process.env.INTERNAL_SERVICE_TOKEN;
  if (!token?.trim()) {
    throw new Error('Configuration Error: INTERNAL_SERVICE_TOKEN is required.');
  }
  return {
    'X-Internal-Service-Token': token,
    'X-Service-Name': 'bidding-service',
    ...extra,
  };
}

async function serviceError(service: string, response: Response): Promise<ServiceClientError> {
  const body = await response.json().catch(() => ({})) as ErrorBody;
  const nested = typeof body.error === 'object' ? body.error : undefined;
  const code = nested?.code
    || body.code
    || (typeof body.error === 'string' ? body.error : undefined)
    || body.message
    || `${service.toUpperCase()}_SERVICE_ERROR`;
  return new ServiceClientError(
    service,
    response.status,
    code,
    nested?.message || body.message || code,
  );
}

async function serviceFetch(
  service: string,
  input: string | URL,
  init?: RequestInit,
): Promise<Response> {
  try {
    return await fetch(input, init);
  } catch {
    throw new ServiceClientError(
      service,
      503,
      `${service.toUpperCase()}_SERVICE_UNAVAILABLE`,
      `${service} service is unavailable`,
    );
  }
}

export type PassengerProfile = {
  id: string;
  name: string;
  rating?: string;
};

export class PassengerClient {
  constructor(private readonly baseUrl: string) {}

  async fetchPassengersBatch(
    passengerIds: string[],
  ): Promise<Record<string, PassengerProfile>> {
    if (passengerIds.length === 0) return {};
    try {
      const response = await serviceFetch(
        'passenger',
        new URL('/passengers/batch', this.baseUrl),
        {
          method: 'POST',
          headers: internalHeaders({ 'Content-Type': 'application/json' }),
          body: JSON.stringify({ ids: passengerIds }),
        },
      );
      if (response.ok) {
        return await response.json() as Record<string, PassengerProfile>;
      }
    } catch (error) {
      Logger.error('PassengerClient.fetchPassengersBatch failed:', error);
    }
    return {};
  }

  async checkRideAccess(passengerId: string): Promise<void> {
    const response = await serviceFetch(
      'passenger',
      new URL(`/passengers/internal/${passengerId}/ride-access`, this.baseUrl),
      { headers: internalHeaders() },
    );
    if (!response.ok) throw await serviceError('passenger', response);
    const body = await response.json().catch(() => ({})) as {
      allowed?: boolean;
      code?: string | null;
    };
    if (!body.allowed) {
      throw new ServiceClientError(
        'passenger',
        403,
        body.code || 'ACCOUNT_RESTRICTED',
        body.code || 'ACCOUNT_RESTRICTED',
      );
    }
  }
}

export type DriverProfile = {
  id: string;
  name: string;
  rating?: number;
  vehicleType?: string;
  plateNumber?: string;
};

export type DriverEligibility = {
  eligible: boolean;
  code: string | null;
  message: string | null;
  availableBalanceCentavos: number;
  requiredCommissionCentavos: number;
};

export class DriverClient {
  constructor(private readonly baseUrl: string) {}

  async fetchProfile(driverId: string): Promise<DriverProfile> {
    const response = await serviceFetch(
      'driver',
      new URL(`/drivers/internal/${driverId}/profile`, this.baseUrl),
      { headers: internalHeaders() },
    );
    if (!response.ok) throw await serviceError('driver', response);
    return await response.json() as DriverProfile;
  }

  async checkEligibility(
    driverId: string,
    requiredCommissionCentavos: number,
  ): Promise<DriverEligibility> {
    const response = await serviceFetch(
      'driver',
      new URL('/drivers/internal/eligibility', this.baseUrl),
      {
        method: 'POST',
        headers: internalHeaders({ 'Content-Type': 'application/json' }),
        body: JSON.stringify({ driverId, requiredCommissionCentavos }),
      },
    );
    if (!response.ok) throw await serviceError('driver', response);
    return await response.json() as DriverEligibility;
  }
}

export type ActiveRide = {
  id: string;
  status: string;
  ride_type: string;
  driver_id?: string | null;
};

export class TripClient {
  constructor(private readonly baseUrl: string) {}

  async fetchDriverActiveRides(driverId: string): Promise<ActiveRide[]> {
    const response = await serviceFetch(
      'trip',
      new URL(`/rides/driver/${driverId}`, this.baseUrl),
      { headers: internalHeaders() },
    );
    if (!response.ok) throw await serviceError('trip', response);
    const rides = await response.json() as ActiveRide[];
    return rides.filter(
      (ride) => ['accepted', 'arrived', 'in_transit'].includes(ride.status),
    );
  }

  async createRide(
    payload: Record<string, unknown>,
    idempotencyKey: string,
  ): Promise<{ id: string }> {
    const response = await serviceFetch(
      'trip',
      new URL('/rides/internal', this.baseUrl),
      {
        method: 'POST',
        headers: internalHeaders({
          'Content-Type': 'application/json',
          'Idempotency-Key': idempotencyKey,
        }),
        body: JSON.stringify(payload),
      },
    );
    if (!response.ok) throw await serviceError('trip', response);
    return await response.json() as { id: string };
  }

  async getRide(rideId: string): Promise<ActiveRide> {
    const response = await serviceFetch(
      'trip',
      new URL(`/rides/${rideId}`, this.baseUrl),
      { headers: internalHeaders() },
    );
    if (!response.ok) throw await serviceError('trip', response);
    return await response.json() as ActiveRide;
  }

  async acceptRide(
    rideId: string,
    input: {
      driverId: string;
      assignmentSource: 'driver_offer' | 'admin';
      assignedByAdminId?: string | null;
      idempotencyKey: string;
    },
  ): Promise<void> {
    const response = await serviceFetch(
      'trip',
      new URL(`/rides/internal/${rideId}/accept`, this.baseUrl),
      {
        method: 'POST',
        headers: internalHeaders({
          'Content-Type': 'application/json',
          'Idempotency-Key': input.idempotencyKey,
        }),
        body: JSON.stringify({
          driver_id: input.driverId,
          assignment_source: input.assignmentSource,
          assigned_by_admin_id: input.assignedByAdminId ?? null,
        }),
      },
    );
    if (response.ok) return;

    const ride = await this.getRide(rideId).catch(() => null);
    if (
      ride
      && ride.driver_id === input.driverId
      && ['accepted', 'arrived', 'in_transit', 'completed'].includes(ride.status)
    ) {
      return;
    }
    throw await serviceError('trip', response);
  }

  async cancelRide(rideId: string, idempotencyKey: string): Promise<void> {
    const response = await serviceFetch(
      'trip',
      new URL(`/rides/internal/${rideId}/status`, this.baseUrl),
      {
        method: 'POST',
        headers: internalHeaders({
          'Content-Type': 'application/json',
          'Idempotency-Key': idempotencyKey,
        }),
        body: JSON.stringify({ status: 'canceled' }),
      },
    );
    if (response.ok) return;

    const ride = await this.getRide(rideId).catch(() => null);
    if (ride?.status === 'canceled') return;
    throw await serviceError('trip', response);
  }
}

export class AdminClient {
  constructor(private readonly baseUrl: string) {}

  async checkZones(payload: Record<string, number>): Promise<void> {
    const response = await serviceFetch(
      'admin',
      new URL('/admin/internal/zones/check', this.baseUrl),
      {
        method: 'POST',
        headers: internalHeaders({ 'Content-Type': 'application/json' }),
        body: JSON.stringify(payload),
      },
    );
    if (!response.ok) throw await serviceError('admin', response);
    const body = await response.json().catch(() => ({})) as {
      allowed?: boolean;
      code?: string;
    };
    if (!body.allowed) {
      throw new ServiceClientError(
        'admin',
        403,
        body.code || 'OUTSIDE_SERVICE_ZONE',
        body.code || 'OUTSIDE_SERVICE_ZONE',
      );
    }
  }

  async currentCommission(): Promise<number> {
    const response = await serviceFetch(
      'admin',
      new URL('/admin/internal/pricing/commission', this.baseUrl),
      { headers: internalHeaders() },
    );
    if (!response.ok) throw await serviceError('admin', response);
    const body = await response.json() as { rate_basis_points?: number };
    if (!Number.isInteger(body.rate_basis_points)) {
      throw new ServiceClientError(
        'admin',
        502,
        'COMMISSION_POLICY_UNAVAILABLE',
        'COMMISSION_POLICY_UNAVAILABLE',
      );
    }
    return body.rate_basis_points!;
  }
}

type FareEstimate = {
  serviceType?: string;
  service_type?: string;
  totalFare?: number;
  total_fare?: number;
  [key: string]: unknown;
};

export class FareClient {
  constructor(private readonly baseUrl: string) {}

  async estimateFare(
    rideType: string,
    distanceKm: number,
    durationMinutes: number,
  ): Promise<{ amount: number; estimate: FareEstimate }> {
    const response = await serviceFetch(
      'fare',
      new URL('/fares/estimate', this.baseUrl),
      {
        method: 'POST',
        headers: internalHeaders({ 'Content-Type': 'application/json' }),
        body: JSON.stringify({ rideType, distanceKm, durationMinutes }),
      },
    );
    if (!response.ok) throw await serviceError('fare', response);
    const body = await response.json() as {
      data?: { estimates?: FareEstimate[] };
    };
    const estimate = body.data?.estimates?.find((item) => (
      (item.serviceType ?? item.service_type) === rideType
    ));
    const amount = estimate?.totalFare ?? estimate?.total_fare;
    if (!estimate || typeof amount !== 'number' || !Number.isFinite(amount)) {
      throw new ServiceClientError(
        'fare',
        502,
        'FARE_RULE_NOT_FOUND',
        `No active fare rule exists for '${rideType}'.`,
      );
    }
    return { amount, estimate };
  }
}

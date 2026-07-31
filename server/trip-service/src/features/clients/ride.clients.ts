/**
 * HTTP gateway adapter encapsulating all outbound calls from trip-service to passenger-service.
 * Falls back to a default name on any downstream failure so ride creation never blocks.
 */
import { Logger } from '../../shared/logger/logger.ts';

export class PassengerClient {
  constructor(private readonly baseUrl: string) {}

  /**
   * Resolves a single passenger's display name for embedding in ride records at creation time.
   * Returns 'Passenger' on any network or parse failure — ride creation must not be blocked
   * by an unavailable passenger service.
   */
  async fetchPassengerName(passengerId: string): Promise<string> {
    if (!passengerId) return 'Passenger';
    try {
      const response = await fetch(new URL('/passengers/batch', this.baseUrl), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ids: [passengerId] }),
      });
      if (response.ok) {
        const passengers = (await response.json()) as Record<string, { name?: string }>;
        return passengers[passengerId]?.name || 'Passenger';
      }
    } catch (err) {
      Logger.error('PassengerClient.fetchPassengerName failed:', err);
    }
    return 'Passenger';
  }

  async checkRideAccess(passengerId: string): Promise<void> {
    const response = await fetch(
      new URL(`/passengers/internal/${passengerId}/ride-access`, this.baseUrl),
      { headers: internalHeaders() },
    );
    const body = await response.json().catch(() => ({})) as {
      allowed?: boolean;
      code?: string;
    };
    if (!response.ok) {
      throw new Error(body.code || 'PASSENGER_SERVICE_UNAVAILABLE');
    }
    if (!body.allowed) {
      throw new Error(body.code || 'ACCOUNT_RESTRICTED');
    }
  }
}

function internalHeaders(extra: Record<string, string> = {}) {
  const token = process.env.INTERNAL_SERVICE_TOKEN;
  if (!token) throw new Error('Configuration Error: INTERNAL_SERVICE_TOKEN is required.');
  return {
    'X-Internal-Service-Token': token,
    ...extra,
  };
}

export type DriverProfile = {
  id: string;
  name: string;
  rating?: number;
  vehicleType?: string;
  plateNumber?: string;
  vehicle_type?: string;
  plate_number?: string;
};

export class DriverClient {
  constructor(private readonly baseUrl: string) {}

  async checkEligibility(driverId: string): Promise<void> {
    const response = await fetch(
      new URL('/drivers/internal/eligibility', this.baseUrl),
      {
        method: 'POST',
        headers: internalHeaders({ 'Content-Type': 'application/json' }),
        body: JSON.stringify({
          driverId,
          requiredCommissionCentavos: 0,
        }),
      },
    );
    const body = await response.json().catch(() => ({})) as {
      eligible?: boolean;
      code?: string | null;
    };
    if (!response.ok) {
      throw new Error(body.code || 'DRIVER_SERVICE_UNAVAILABLE');
    }
    if (!body.eligible) {
      throw new Error(body.code || 'DRIVER_NOT_ELIGIBLE');
    }
  }

  async fetchProfile(driverId: string): Promise<DriverProfile> {
    const response = await fetch(
      new URL(`/drivers/internal/${driverId}/profile`, this.baseUrl),
      { headers: internalHeaders() },
    );
    if (!response.ok) throw new Error('DRIVER_NOT_FOUND');
    return await response.json() as DriverProfile;
  }

  async reserve(input: {
    driverId: string;
    rideId: string;
    fareCentavos: number;
    commissionBasisPoints: number;
    idempotencyKey: string;
  }) {
    const response = await fetch(
      new URL('/drivers/internal/credits/reservations', this.baseUrl),
      {
        method: 'POST',
        headers: internalHeaders({
          'Content-Type': 'application/json',
          'Idempotency-Key': input.idempotencyKey,
          'X-Service-Name': 'trip-service',
        }),
        body: JSON.stringify(input),
      },
    );
    const body = await response.json().catch(() => ({})) as Record<string, any>;
    if (!response.ok) {
      throw new Error(String(body.code || body.message || 'INSUFFICIENT_CREDIT'));
    }
    return body as {
      reservation: { id: string; commissionCentavos: number };
      commissionCentavos: number;
    };
  }

  async updateReservation(
    rideId: string,
    action: 'settle' | 'release' | 'dispute',
    idempotencyKey: string,
    reason?: string,
  ) {
    const response = await fetch(
      new URL(`/drivers/internal/credits/reservations/${rideId}/${action}`, this.baseUrl),
      {
        method: 'POST',
        headers: internalHeaders({
          'Content-Type': 'application/json',
          'Idempotency-Key': idempotencyKey,
          'X-Service-Name': 'trip-service',
        }),
        body: JSON.stringify({ reason }),
      },
    );
    if (!response.ok) {
      const body = await response.json().catch(() => ({})) as Record<string, unknown>;
      throw new Error(String(body.code || body.message || 'CREDIT_SETTLEMENT_FAILED'));
    }
    return await response.json();
  }
}

export class AdminClient {
  constructor(private readonly baseUrl: string) {}

  async checkZones(payload: Record<string, number>) {
    const response = await fetch(
      new URL('/admin/internal/zones/check', this.baseUrl),
      {
        method: 'POST',
        headers: internalHeaders({ 'Content-Type': 'application/json' }),
        body: JSON.stringify(payload),
      },
    );
    const body = await response.json().catch(() => ({})) as {
      allowed?: boolean;
      code?: string;
    };
    if (!response.ok || !body.allowed) {
      throw new Error(body.code || 'OUTSIDE_SERVICE_ZONE');
    }
    return body;
  }

  async currentCommission(): Promise<number> {
    const response = await fetch(
      new URL('/admin/internal/pricing/commission', this.baseUrl),
      { headers: internalHeaders() },
    );
    if (!response.ok) throw new Error('COMMISSION_POLICY_UNAVAILABLE');
    const body = await response.json() as { rate_basis_points?: number };
    return body.rate_basis_points ?? 1000;
  }
}

export class FareClient {
  constructor(private readonly baseUrl: string) {}

  async recordSnapshot(input: {
    rideId: string;
    driverId: string;
    serviceType: string;
    totalFareCentavos: number;
    commissionRateBasisPoints: number;
    commissionCentavos: number;
    assignmentSource: 'driver_offer' | 'admin';
    idempotencyKey: string;
  }) {
    const response = await fetch(
      new URL('/fares/internal/transactions', this.baseUrl),
      {
        method: 'POST',
        headers: internalHeaders({
          'Content-Type': 'application/json',
          'Idempotency-Key': input.idempotencyKey,
          'X-Service-Name': 'trip-service',
        }),
        body: JSON.stringify(input),
      },
    );
    if (!response.ok) {
      const body = await response.json().catch(() => ({})) as Record<string, unknown>;
      throw new Error(String(body.code || body.message || body.error || 'FARE_SNAPSHOT_FAILED'));
    }
    return await response.json();
  }

  async updatePaymentStatus(
    rideId: string,
    paymentStatus: 'cash_received' | 'cash_disputed' | 'canceled',
    idempotencyKey: string,
  ) {
    const response = await fetch(
      new URL(`/fares/internal/transactions/${rideId}/status`, this.baseUrl),
      {
        method: 'POST',
        headers: internalHeaders({
          'Content-Type': 'application/json',
          'Idempotency-Key': idempotencyKey,
          'X-Service-Name': 'trip-service',
        }),
        body: JSON.stringify({ paymentStatus }),
      },
    );
    if (!response.ok) {
      const body = await response.json().catch(() => ({})) as Record<string, unknown>;
      throw new Error(String(body.code || body.message || body.error || 'FARE_STATUS_FAILED'));
    }
    return await response.json();
  }
}

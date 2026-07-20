/**
 * HTTP gateway adapters isolating all cross-service fetch logic from business orchestration.
 * Each client wraps one downstream service. Errors are caught and logged to prevent cascading
 * failures from propagating into the bidding session state machine.
 */
import { Logger } from '../../shared/logger/logger.ts';

export type PassengerProfile = {
  id: string;
  name: string;
  rating?: string;
};

export class PassengerClient {
  constructor(private readonly baseUrl: string) {}

  /**
   * Resolves multiple passenger profiles in a single POST instead of N per-passenger fetches.
   * Returns an id→profile map; missing entries are omitted rather than throwing.
   */
  async fetchPassengersBatch(passengerIds: string[]): Promise<Record<string, PassengerProfile>> {
    if (passengerIds.length === 0) return {};
    try {
      const response = await fetch(
        new URL('/passengers/batch', this.baseUrl).toString(),
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ ids: passengerIds }),
        }
      );
      if (response.ok) {
        return await response.json() as Record<string, PassengerProfile>;
      }
    } catch (err) {
      Logger.error('PassengerClient.fetchPassengersBatch failed:', err);
    }
    return {};
  }
}

export type ActiveRide = {
  id: string;
  status: string;
  ride_type: string;
};

export class TripClient {
  constructor(private readonly baseUrl: string) {}

  /**
   * Fetches the active ride list for a driver to enforce the concurrency cap and
   * priority-ride exclusivity rules before a driver offer is persisted.
   */
  async fetchDriverActiveRides(driverId: string): Promise<ActiveRide[]> {
    try {
      const response = await fetch(
        new URL(`/rides/driver/${driverId}`, this.baseUrl).toString()
      );
      if (response.ok) {
        const rides = await response.json() as ActiveRide[];
        return rides.filter(
          (ride) => ride.status === 'accepted' || ride.status === 'arrived' || ride.status === 'in_transit'
        );
      }
    } catch (err) {
      Logger.error('TripClient.fetchDriverActiveRides failed:', err);
    }
    return [];
  }

  /**
   * Creates a pending ride record on the trip service. Called before the local
   * acceptOfferTransaction so the trip ID is available for the final accept call.
   */
  async createRide(payload: Record<string, unknown>): Promise<{ id: string } | null> {
    const response = await fetch(
      new URL('/rides', this.baseUrl).toString(),
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      }
    );
    if (!response.ok) {
      const errBody = await response.json().catch(() => ({}));
      throw new Error(`Trip service rejected ride creation: ${JSON.stringify(errBody)}`);
    }
    return response.json() as Promise<{ id: string }>;
  }

  /**
   * Assigns the winning driver to an already-created ride record. Called after the
   * local bidding DB transaction commits, so a failure here is non-fatal (the ride
   * remains in pending state and can be retried).
   */
  async acceptRide(rideId: string, driverData: Record<string, unknown>): Promise<void> {
    await fetch(
      new URL(`/rides/${rideId}/accept`, this.baseUrl).toString(),
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(driverData),
      }
    ).catch((err) => {
      Logger.error(`TripClient.acceptRide failed for ride ${rideId}:`, err);
    });
  }

  /**
   * Saga compensating action: cancels the remote ride record when the local
   * acceptOfferTransaction fails after createRide already succeeded, preventing
   * phantom rides from persisting in the trip service.
   */
  async cancelRide(rideId: string): Promise<void> {
    await fetch(
      new URL(`/rides/${rideId}/status`, this.baseUrl).toString(),
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: 'canceled' }),
      }
    ).catch((err) => {
      Logger.error(`TripClient.cancelRide (Saga rollback) failed for ride ${rideId}:`, err);
    });
  }
}

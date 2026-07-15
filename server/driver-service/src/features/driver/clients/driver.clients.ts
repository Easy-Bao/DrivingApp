/**
 * HTTP gateway adapter encapsulating all outbound calls from driver-service to trip-service.
 * Centralises URL construction and absorbs network errors so the service layer stays declarative.
 */
import { Logger } from '../../../shared/logger/logger.ts';

export type RideRecord = {
  id: string;
  status: string;
  fare: number;
  ride_type: string;
  created_at: string;
  driver_name?: string;
  plate_number?: string;
};

export class TripClient {
  constructor(private readonly baseUrl: string) {}

  /**
   * Retrieves all ride records assigned to a driver, used for stats aggregation and trip history.
   * Returns an empty array on downstream failure to prevent stats endpoints from erroring out.
   */
  async fetchDriverRides(driverId: string): Promise<RideRecord[]> {
    try {
      const response = await fetch(
        new URL(`/rides/driver/${driverId}`, this.baseUrl).toString()
      );
      if (response.ok) {
        return await response.json() as RideRecord[];
      }
      Logger.error(`TripClient.fetchDriverRides returned ${response.status} for driver ${driverId}`);
    } catch (err) {
      Logger.error('TripClient.fetchDriverRides failed:', err);
    }
    return [];
  }

  /**
   * Retrieves the full active ride board. Used by drivers to view open ride requests.
   * Propagates the failure so the controller can return an appropriate HTTP error.
   */
  async fetchActiveRides(): Promise<RideRecord[]> {
    const response = await fetch(
      new URL('/rides/active', this.baseUrl).toString()
    );
    if (!response.ok) {
      throw new Error(`Trip service unavailable with status ${response.status}`);
    }
    return response.json() as Promise<RideRecord[]>;
  }
}

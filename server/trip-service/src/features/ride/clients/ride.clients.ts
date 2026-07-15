/**
 * HTTP gateway adapter encapsulating all outbound calls from trip-service to passenger-service.
 * Falls back to a default name on any downstream failure so ride creation never blocks.
 */
import { Logger } from '../../../shared/logger/logger.ts';

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
      const response = await fetch(
        new URL(`/passengers/${passengerId}`, this.baseUrl).toString()
      );
      if (response.ok) {
        const passenger = await response.json() as any;
        return passenger?.name || 'Passenger';
      }
    } catch (err) {
      Logger.error('PassengerClient.fetchPassengerName failed:', err);
    }
    return 'Passenger';
  }
}

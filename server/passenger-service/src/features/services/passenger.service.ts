/**
 * Service layer orchestrating domain logic for passenger profiles, ride requests, ride history, and notifications.
 */
import { HTTPException } from 'hono/http-exception';
import { Passenger, PassengerRepository, SafePassenger } from '../entities/passenger.types.ts';
import { CreateRideRequest } from '../schemas/passenger.schema.ts';

export class PassengerService {
  private repository: PassengerRepository;

  constructor(repository: PassengerRepository) {
    this.repository = repository;
  }

  private sanitizePassenger(passenger: Passenger): SafePassenger {
    const { password_hash: _, ...safePassenger } = passenger;
    return safePassenger;
  }

  async getPassengerProfile(passengerId: string): Promise<SafePassenger> {
    const passengerProfile = await this.repository.retrievePassengerProfile(passengerId);
    if (!passengerProfile) {
      throw new HTTPException(404, { message: `Passenger not found: ${passengerId}` });
    }
    return this.sanitizePassenger(passengerProfile);
  }

  async getPassengersBatch(passengerIds: string[]): Promise<Record<string, SafePassenger>> {
    const passengerMap = await this.repository.retrievePassengersByIds(passengerIds);
    return Object.fromEntries(
      Object.entries(passengerMap).map(([id, passenger]) => [id, this.sanitizePassenger(passenger)])
    );
  }

  async updatePassengerProfile(id: string, payload: { name: string; phone: string; email: string }): Promise<SafePassenger> {
    const updated = await this.repository.updatePassengerProfile({ id, ...payload });
    return this.sanitizePassenger(updated);
  }

  async createRideRequest(payload: CreateRideRequest) {
    return await this.repository.registerRideRequest(payload);
  }

  async getPassengerRideHistory(passengerId: string) {
    return await this.repository.retrievePassengerRideHistory(passengerId);
  }

  async getPassengerNotifications(passengerId: string) {
    return await this.repository.retrievePassengerNotifications(passengerId);
  }
}

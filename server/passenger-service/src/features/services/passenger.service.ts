/**
 * Service layer orchestrating domain logic for passenger profiles, ride requests, ride history, and notifications.
 */
import { HTTPException } from 'hono/http-exception';
import { PassengerRepository } from '../entities/passenger.types.ts';
import { CreateRideRequest } from '../schemas/passenger.schema.ts';

export class PassengerService {
  private repository: PassengerRepository;

  constructor(repository: PassengerRepository) {
    this.repository = repository;
  }

  async getPassengerProfile(passengerId: string) {
    const passengerProfile = await this.repository.retrievePassengerProfile(passengerId);
    if (!passengerProfile) {
      throw new HTTPException(404, { message: `Passenger not found: ${passengerId}` });
    }
    const { password_hash, ...passengerProfileWithoutPassword } = passengerProfile as any;
    return passengerProfileWithoutPassword;
  }

  async getPassengersBatch(passengerIds: string[]): Promise<Record<string, any>> {
    const passengerMap = await this.repository.retrievePassengersByIds(passengerIds);
    return Object.fromEntries(
      Object.entries(passengerMap).map(([id, passenger]) => {
        const { password_hash, ...safePassenger } = passenger as any;
        return [id, safePassenger];
      })
    );
  }

  async updatePassengerProfile(id: string, payload: { name: string; phone: string; email: string }) {
    const updated = await this.repository.updatePassengerProfile({ id, ...payload });
    const { password_hash, ...passengerWithoutPassword } = updated as any;
    return passengerWithoutPassword;
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

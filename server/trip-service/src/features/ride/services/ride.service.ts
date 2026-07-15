/**
 * Service layer orchestrating domain logic for ride requests, matching constraints, and status updates.
 * Cross-service passenger name resolution is delegated to PassengerClient.
 */
import { RideRepository } from '../entities/ride.types.ts';
import { HTTPException } from 'hono/http-exception';
import { PassengerClient } from '../clients/ride.clients.ts';

export class RideService {
  private readonly repository: RideRepository;
  private readonly passengerClient: PassengerClient;

  constructor(repository: RideRepository) {
    const passengerServiceUrl = process.env.PASSENGER_SERVICE_URL;
    if (!passengerServiceUrl) {
      throw new Error('Configuration Error: PASSENGER_SERVICE_URL is required but not set.');
    }
    this.repository = repository;
    this.passengerClient = new PassengerClient(passengerServiceUrl);
  }

  async createRideRequest(payload: any) {
    const passengerName = await this.passengerClient.fetchPassengerName(payload.passenger_id);
    return await this.repository.createRide({ ...payload, passenger_name: passengerName });
  }

  async getRideDetails(id: string) {
    const found = await this.repository.findRideById(id);
    if (!found) {
      throw new HTTPException(404, { message: 'Ride request not found' });
    }
    return found;
  }

  async getActiveRideRequests() {
    return await this.repository.findActiveRides();
  }

  async getRidesByDriverId(driverId: string) {
    return await this.repository.findRidesByDriverId(driverId);
  }

  async getRidesByPassengerId(passengerId: string) {
    return await this.repository.findRidesByPassengerId(passengerId);
  }

  async acceptRideRequest(id: string, driverData: any) {
    try {
      return await this.repository.acceptRideTransaction(id, driverData);
    } catch (error: any) {
      if (error.message === 'Driver Max Cap Reached') {
        throw new HTTPException(400, {
          message: 'Driver has reached the maximum cap of 5 concurrent accepted ride requests',
        });
      }
      if (
        error.message === 'Driver has active priority' ||
        error.message === 'Cannot accept priority with active rides'
      ) {
        throw new HTTPException(400, { message: 'Priority Ride constraints violated' });
      }
      if (error.message === 'Ride not found') {
        throw new HTTPException(404, { message: 'Ride request not found' });
      }
      throw new HTTPException(400, { message: error.message });
    }
  }

  async updateRideStatus(id: string, status: string) {
    const isTerminalStatus =
      status === 'completed' || status === 'canceled' || status === 'cancelled';
    try {
      return await this.repository.updateRideStatus(
        id,
        status,
        isTerminalStatus ? new Date() : undefined
      );
    } catch (error: any) {
      throw new HTTPException(404, { message: 'Ride request not found' });
    }
  }
}

/**
 * Service layer orchestrating domain logic for driver operational status, profile stats, trip history aggregation, and reviews.
 * All cross-service HTTP calls are delegated to TripClient to keep this class free of network concerns.
 */
import { Driver, DriverRepository, SafeDriver } from '../entities/driver.types.ts';
import { UpdateOnlineStatusRequest } from '../schemas/driver.schema.ts';
import { HTTPException } from 'hono/http-exception';
import { TripClient } from '../clients/driver.clients.ts';

export class DriverService {
  private readonly repository: DriverRepository;
  private readonly tripClient: TripClient;

  constructor(repository: DriverRepository) {
    const tripServiceUrl = process.env.TRIP_SERVICE_URL;
    if (!tripServiceUrl) {
      throw new Error('Configuration Error: TRIP_SERVICE_URL is required but not set.');
    }
    this.repository = repository;
    this.tripClient = new TripClient(tripServiceUrl);
  }

  private sanitizeDriver(driver: Driver): SafeDriver {
    const { passwordHash: _, ...safeDriverData } = driver;
    return safeDriverData;
  }

  async getOnlineDrivers(): Promise<SafeDriver[]> {
    const onlineDrivers = await this.repository.findOnlineDrivers();
    return onlineDrivers.map((driver) => this.sanitizeDriver(driver));
  }

  async updateOnlineStatus(driverId: string, payload: UpdateOnlineStatusRequest): Promise<SafeDriver> {
    try {
      const updated = await this.repository.updateOnlineStatus(
        driverId,
        payload.isOnline,
        payload.lat ?? undefined,
        payload.lng ?? undefined
      );
      return this.sanitizeDriver(updated);
    } catch (err) {
      throw new HTTPException(404, { message: 'Driver not found' });
    }
  }

  async getDriverProfile(driverId: string): Promise<SafeDriver> {
    const foundDriver = await this.repository.findDriverById(driverId);
    if (!foundDriver) {
      throw new HTTPException(404, { message: 'Driver not found' });
    }
    return this.sanitizeDriver(foundDriver);
  }

  async getDriverStats(driverId: string) {
    const foundDriver = await this.repository.findDriverById(driverId);
    if (!foundDriver) {
      throw new HTTPException(404, { message: 'Driver not found' });
    }

    const driverRides = await this.tripClient.fetchDriverRides(driverId);

    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);

    const todayRides = driverRides.filter((rideRecord) => {
      const createdAt = new Date(rideRecord.created_at);
      return createdAt >= startOfToday && rideRecord.status === 'completed';
    });

    const todayEarnings = todayRides.reduce(
      (accumulatedFare, rideRecord) => accumulatedFare + (rideRecord.fare ?? 0),
      0
    );
    const todayTrips = todayRides.length;
    const baseHours = todayTrips * 0.75;
    const hoursOnline = parseFloat(
      (foundDriver.isOnline ? baseHours + 0.5 : baseHours).toFixed(1)
    );

    const completedRides = driverRides.filter((rideRecord) => rideRecord.status === 'completed');
    const cancelledRides = driverRides.filter((rideRecord) => rideRecord.status === 'cancelled');

    const totalTrips = completedRides.length;
    const lifetimeEarnings = completedRides.reduce(
      (accumulatedFare, rideRecord) => accumulatedFare + (rideRecord.fare ?? 0),
      0
    );

    const totalAssigned = completedRides.length + cancelledRides.length;
    const acceptanceRate = totalAssigned > 0
      ? Math.round((completedRides.length / totalAssigned) * 100)
      : 98;

    return {
      todayEarnings,
      todayTrips,
      hoursOnline,
      lifetimeEarnings,
      totalTrips,
      acceptanceRate,
    };
  }

  async getDriverTripHistory(driverId: string) {
    try {
      return await this.tripClient.fetchDriverRides(driverId);
    } catch (err) {
      throw new HTTPException(500, { message: 'Failed to fetch trip history from trip service' });
    }
  }

  async getActiveRideRequests() {
    try {
      return await this.tripClient.fetchActiveRides();
    } catch (err: unknown) {
      const errorMessage = err instanceof Error ? err.message : 'Trip service unavailable';
      throw new HTTPException(500, { message: errorMessage });
    }
  }

  async getDriverReviews(driverId: string, page = 1, limit = 5) {
    const uuidFormatRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

    if (!uuidFormatRegex.test(driverId)) {
      return [];
    }

    return await this.repository.fetchDriverReviews(driverId, page, limit);
  }

  async addDriverReview(driverId: string, payload: { passengerName: string; rating: number; comment: string }) {
    const review = await this.repository.addDriverReview({
      driverId,
      passengerName: payload.passengerName,
      rating: payload.rating,
      comment: payload.comment,
    });

    const allReviews = await this.repository.fetchDriverReviews(driverId);
    if (allReviews.length > 0) {
      const sum = allReviews.reduce((acc, r) => acc + r.rating, 0);
      const avgRating = parseFloat((sum / allReviews.length).toFixed(2));
      await this.repository.updateDriverRating(driverId, avgRating);
    }

    return review;
  }
}

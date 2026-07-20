/**
 * Service layer orchestrating domain logic for driver accounts, online status, trip history aggregation, and reviews.
 * All cross-service HTTP calls are delegated to TripClient to keep this class free of network concerns.
 */
import { DriverRepository } from '../entities/driver.types.ts';
import { CreateDriverRequest, LoginDriverRequest, UpdateOnlineStatusRequest } from '../schemas/driver.schema.ts';
import { HTTPException } from 'hono/http-exception';
import { Logger } from '../../shared/logger/logger.ts';
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

  async registerDriver(payload: CreateDriverRequest) {
    const existing = await this.repository.findDriverByEmail(payload.email);
    if (existing) {
      throw new HTTPException(409, { message: 'A driver with this email already exists' });
    }
    const created = await this.repository.registerDriver(payload);
    const { passwordHash: _, ...safeDriverData } = created as any;
    return safeDriverData;
  }

  async authenticateDriver(payload: LoginDriverRequest) {
    const foundDriver = await this.repository.findDriverByEmail(payload.email);
    if (!foundDriver) {
      throw new HTTPException(401, { message: 'Invalid email or password' });
    }
    const isPasswordValid = await Bun.password.verify(payload.password, foundDriver.passwordHash);
    if (!isPasswordValid) {
      throw new HTTPException(401, { message: 'Invalid email or password' });
    }
    const { passwordHash: _, ...safeDriverData } = foundDriver as any;
    return safeDriverData;
  }

  async getOnlineDrivers() {
    const onlineDrivers = await this.repository.findOnlineDrivers();
    return onlineDrivers.map(({ passwordHash: _, ...safeDriverData }) => safeDriverData);
  }

  async updateOnlineStatus(driverId: string, payload: UpdateOnlineStatusRequest) {
    try {
      const updated = await this.repository.updateOnlineStatus(
        driverId,
        payload.isOnline,
        payload.lat ?? undefined,
        payload.lng ?? undefined
      );
      const { passwordHash: _, ...safeDriverData } = updated as any;
      return safeDriverData;
    } catch (err) {
      throw new HTTPException(404, { message: 'Driver not found' });
    }
  }

  async getDriverProfile(driverId: string) {
    const foundDriver = await this.repository.findDriverById(driverId);
    if (!foundDriver) {
      throw new HTTPException(404, { message: 'Driver not found' });
    }
    const { passwordHash: _, ...safeDriverData } = foundDriver as any;
    return safeDriverData;
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
    } catch (err: any) {
      throw new HTTPException(500, { message: err.message || 'Trip service unavailable' });
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

import { db } from '../../shared/drizzle.ts';
import { passengers, rideRequests } from '../../db/schema.ts';
import { eq, desc, inArray } from 'drizzle-orm';
import {
  Passenger,
  RideRequest,
  RideType,
  UpdatePassengerOptions,
  PassengerRepository,
} from '../entities/passenger.types.ts';
import { CreatePassengerRequest, CreateRideRequest } from '../schemas/passenger.schema.ts';
import { Logger } from '../../shared/logger/logger.ts';

function mapPassenger(dbPassenger: any): Passenger {
  return {
    id: dbPassenger.id,
    name: dbPassenger.name,
    email: dbPassenger.email,
    phone: dbPassenger.phone,
    preferred_ride_type: dbPassenger.preferredRideType as RideType | null,
    created_at: dbPassenger.createdAt,
    password_hash: dbPassenger.passwordHash,
    is_verified: dbPassenger.isVerified,
  };
}

function mapRideRequest(dbRide: any): RideRequest {
  return {
    id: dbRide.id,
    passenger_id: dbRide.passengerId,
    ride_type: dbRide.rideType as RideType,
    pickup_latitude: dbRide.pickupLatitude,
    pickup_longitude: dbRide.pickupLongitude,
    pickup_name: dbRide.pickupName,
    dropoff_latitude: dbRide.dropoffLatitude,
    dropoff_longitude: dbRide.dropoffLongitude,
    dropoff_name: dbRide.dropoffName,
    fare: dbRide.fare,
    status: dbRide.status,
    created_at: dbRide.createdAt,
  };
}

export class DrizzlePassengerRepository implements PassengerRepository {
  async registerPassenger(passengerDetails: CreatePassengerRequest): Promise<Passenger> {
    const existing = await this.retrievePassengerByEmail(passengerDetails.email);
    if (existing) {
      throw new Error(`A passenger with email ${passengerDetails.email} already exists`);
    }

    const passwordHash = await Bun.password.hash(passengerDetails.password, {
      algorithm: 'bcrypt',
      cost: 10,
    });

    const [createdPassenger] = await db.insert(passengers)
      .values({
        id: crypto.randomUUID(),
        name: passengerDetails.name,
        email: passengerDetails.email,
        phone: passengerDetails.phone,
        preferredRideType: passengerDetails.preferred_ride_type || null,
        passwordHash,
      })
      .returning();

    return mapPassenger(createdPassenger);
  }

  async retrievePassengerProfile(passengerId: string): Promise<Passenger | null> {
    const [fetchedPassenger] = await db.select()
      .from(passengers)
      .where(eq(passengers.id, passengerId));

    if (!fetchedPassenger) return null;
    return mapPassenger(fetchedPassenger);
  }

  async retrievePassengersByIds(passengerIds: string[]): Promise<Record<string, Passenger>> {
    if (passengerIds.length === 0) return {};
    const rows = await db.select()
      .from(passengers)
      .where(inArray(passengers.id, passengerIds));

    return Object.fromEntries(rows.map((row) => [row.id, mapPassenger(row)]));
  }

  async retrievePassengerByEmail(passengerEmail: string): Promise<Passenger | null> {
    const [fetchedPassenger] = await db.select()
      .from(passengers)
      .where(eq(passengers.email, passengerEmail));

    if (!fetchedPassenger) return null;
    return mapPassenger(fetchedPassenger);
  }

  async registerRideRequest(rideDetails: CreateRideRequest): Promise<RideRequest> {
    const passenger = await this.retrievePassengerProfile(rideDetails.passenger_id);
    if (!passenger) {
      throw new Error(`Passenger ID ${rideDetails.passenger_id} not found`);
    }

    const [createdRideRequest] = await db.insert(rideRequests)
      .values({
        id: crypto.randomUUID(),
        passengerId: rideDetails.passenger_id,
        rideType: rideDetails.ride_type,
        pickupLatitude: rideDetails.pickup_latitude,
        pickupLongitude: rideDetails.pickup_longitude,
        pickupName: rideDetails.pickup_name,
        dropoffLatitude: rideDetails.dropoff_latitude,
        dropoffLongitude: rideDetails.dropoff_longitude,
        dropoffName: rideDetails.dropoff_name,
        fare: rideDetails.fare,
        status: 'requested',
      })
      .returning();

    return mapRideRequest(createdRideRequest);
  }

  async retrievePassengerRideHistory(passengerId: string): Promise<RideRequest[]> {
    const passenger = await this.retrievePassengerProfile(passengerId);
    if (!passenger) {
      throw new Error(`Passenger ID ${passengerId} not found`);
    }

    const tripServiceUrl = process.env.TRIP_SERVICE_URL;
    if (!tripServiceUrl) {
      throw new Error("Configuration Error: TRIP_SERVICE_URL is required but not set.");
    }
    const ridesMap = new Map<string, RideRequest>();

    try {
      const localRecords = await db.select()
        .from(rideRequests)
        .where(eq(rideRequests.passengerId, passengerId))
        .orderBy(desc(rideRequests.createdAt));

      for (const rec of localRecords) {
        ridesMap.set(rec.id, {
          id: rec.id,
          passenger_id: rec.passengerId,
          ride_type: rec.rideType as RideType,
          pickup_latitude: rec.pickupLatitude,
          pickup_longitude: rec.pickupLongitude,
          pickup_name: rec.pickupName,
          dropoff_latitude: rec.dropoffLatitude,
          dropoff_longitude: rec.dropoffLongitude,
          dropoff_name: rec.dropoffName,
          fare: rec.fare,
          status: rec.status,
          created_at: rec.createdAt,
          driver_name: '',
          plate_number: '',
          password_hash: '',
        });
      }
    } catch (err) {
      Logger.error('Failed to fetch local ride requests:', err);
    }

    try {
      const tripResponse = await fetch(`${tripServiceUrl}/rides/passenger/${passengerId}`);
      if (tripResponse.ok) {
        const trips = await tripResponse.json() as any[];
        for (const trip of trips) {
          ridesMap.set(trip.id, {
            id: trip.id,
            passenger_id: trip.passenger_id,
            ride_type: trip.ride_type as RideType,
            pickup_latitude: trip.pickup_latitude,
            pickup_longitude: trip.pickup_longitude,
            pickup_name: trip.pickup_name,
            dropoff_latitude: trip.dropoff_latitude,
            dropoff_longitude: trip.dropoff_longitude,
            dropoff_name: trip.dropoff_name,
            fare: trip.fare,
            status: trip.status,
            created_at: new Date(trip.created_at),
            driver_name: trip.driver_name || '',
            plate_number: trip.plate_number || '',
            password_hash: '',
          });
        }
      }
    } catch (err) {
      Logger.error('Failed to fetch rides from trip-service:', err);
    }

    const list = Array.from(ridesMap.values());
    list.sort((a, b) => b.created_at.getTime() - a.created_at.getTime());
    return list;
  }

  async updatePassengerProfile({ id, name, phone, email }: UpdatePassengerOptions): Promise<Passenger> {
    const [updatedPassenger] = await db.update(passengers)
      .set({ name, phone, email })
      .where(eq(passengers.id, id))
      .returning();

    if (!updatedPassenger) {
      throw new Error(`Passenger ID ${id} not found`);
    }

    return mapPassenger(updatedPassenger);
  }

  async verifyPassengerOtp(passengerEmail: string): Promise<void> {
    await db.update(passengers)
      .set({ isVerified: true })
      .where(eq(passengers.email, passengerEmail));
  }

  async retrievePassengerNotifications(passengerId: string): Promise<any[]> {
    const passenger = await this.retrievePassengerProfile(passengerId);
    if (!passenger) {
      throw new Error(`Passenger ID ${passengerId} not found`);
    }
    const localRides = await db.select()
      .from(rideRequests)
      .where(eq(rideRequests.passengerId, passengerId))
      .orderBy(desc(rideRequests.createdAt));

    const notificationsList: any[] = [];
    const tripServiceUrl = process.env.TRIP_SERVICE_URL;
    if (!tripServiceUrl) {
      throw new Error("Configuration Error: TRIP_SERVICE_URL is required but not set.");
    }

    for (const rideRequest of localRides) {
      const tripDetails = await fetchTripStatus(rideRequest.id, rideRequest.status, tripServiceUrl);
      notificationsList.push(...buildNotificationsForRide(rideRequest, tripDetails));
    }

    return notificationsList;
  }
}

interface TripInfo {
  status: string;
  driverName: string;
  plateNumber: string;
}

async function fetchTripStatus(
  rideId: string,
  defaultStatus: string,
  tripServiceUrl: string
): Promise<TripInfo> {
  try {
    const response = await fetch(`${tripServiceUrl}/rides/${rideId}`);
    if (response.ok) {
      const tripDetails = await response.json() as any;
      if (tripDetails) {
        return {
          status: tripDetails.status || defaultStatus,
          driverName: tripDetails.driver_name || '',
          plateNumber: tripDetails.plate_number || '',
        };
      }
    }
  } catch (error) {
    Logger.error(`Failed to fetch ride ${rideId} status from trip-service:`, error);
  }
  return {
    status: defaultStatus,
    driverName: '',
    plateNumber: '',
  };
}

function buildNotificationsForRide(
  rideRequest: { id: string; dropoffName: string; fare: number; createdAt: Date },
  tripDetails: TripInfo
): any[] {
  const notificationsList: any[] = [];
  const baseTime = rideRequest.createdAt.toISOString();
  const { status, driverName, plateNumber } = tripDetails;

  switch (status) {
    case 'requested':
      notificationsList.push({
        id: `req_${rideRequest.id}`,
        title: 'Finding Driver',
        message: `Your ride request to ${rideRequest.dropoffName} is active. Finding a driver...`,
        timestamp: baseTime,
        type: 'ride',
        isRead: false,
      });
      break;

    case 'accepted':
      notificationsList.push({
        id: `acc_${rideRequest.id}`,
        title: 'Driver Found!',
        message: `Driver ${driverName || 'Matched Driver'} (${plateNumber || 'Bao Bao'}) has accepted your ride request.`,
        timestamp: baseTime,
        type: 'driver',
        isRead: false,
      });
      notificationsList.push({
        id: `chat_${rideRequest.id}`,
        title: 'Chat Available',
        message: `You can now chat with your driver, ${driverName || 'your driver'}.`,
        timestamp: baseTime,
        type: 'chat',
        isRead: false,
      });
      break;

    case 'arrived':
      notificationsList.push({
        id: `arr_${rideRequest.id}`,
        title: 'Driver Arrived',
        message: `Your driver, ${driverName || 'your driver'}, has arrived at your pickup location.`,
        timestamp: baseTime,
        type: 'driver',
        isRead: false,
      });
      break;

    case 'in_transit':
      notificationsList.push({
        id: `trans_${rideRequest.id}`,
        title: 'Trip Started',
        message: `You are in transit to ${rideRequest.dropoffName}.`,
        timestamp: baseTime,
        type: 'ride',
        isRead: false,
      });
      break;

    case 'completed':
      notificationsList.push({
        id: `comp_${rideRequest.id}`,
        title: 'Ride Completed',
        message: `Your trip to ${rideRequest.dropoffName} is completed. Total fare: ₱${rideRequest.fare.toFixed(2)}`,
        timestamp: baseTime,
        type: 'ride',
        isRead: true,
      });
      break;

    case 'canceled':
      notificationsList.push({
        id: `canc_${rideRequest.id}`,
        title: 'Ride Canceled ❌',
        message: `Your ride to ${rideRequest.dropoffName} was canceled.`,
        timestamp: baseTime,
        type: 'ride',
        isRead: true,
      });
      break;
  }

  return notificationsList;
}

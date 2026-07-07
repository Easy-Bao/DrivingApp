import { prisma } from '../db.ts';
import { Passenger, RideRequest, RideType } from './types.ts';
import { CreatePassengerRequest, CreateRideRequest } from './schema.ts';
import { PassengerRepository, UpdatePassengerOptions } from './passenger.repository.ts';

export class PrismaPassengerRepository implements PassengerRepository {
  async registerPassenger(passengerDetails: CreatePassengerRequest): Promise<Passenger> {
    const existingPassenger = await prisma.passenger.findUnique({
      where: { email: passengerDetails.email },
    });
    if (existingPassenger) {
      throw new Error(`A passenger with email ${passengerDetails.email} already exists`);
    }
    const passwordHash = await Bun.password.hash(passengerDetails.password, {
      algorithm: 'bcrypt',
      cost: 10,
    });
    const createdPassenger = await prisma.passenger.create({
      data: {
        name: passengerDetails.name,
        email: passengerDetails.email,
        phone: passengerDetails.phone,
        preferred_ride_type: passengerDetails.preferred_ride_type || null,
        password_hash: passwordHash,
      },
    });
    return {
      id: createdPassenger.id,
      name: createdPassenger.name,
      email: createdPassenger.email,
      phone: createdPassenger.phone,
      preferred_ride_type: createdPassenger.preferred_ride_type as RideType | null,
      created_at: createdPassenger.created_at,
      password_hash: createdPassenger.password_hash,
      is_verified: createdPassenger.is_verified,
    };
  }

  async retrievePassengerProfile(passengerId: string): Promise<Passenger | null> {
    const fetchedPassenger = await prisma.passenger.findUnique({
      where: { id: passengerId },
    });
    if (!fetchedPassenger) return null;
    return {
      id: fetchedPassenger.id,
      name: fetchedPassenger.name,
      email: fetchedPassenger.email,
      phone: fetchedPassenger.phone,
      preferred_ride_type: fetchedPassenger.preferred_ride_type as RideType | null,
      created_at: fetchedPassenger.created_at,
      password_hash: fetchedPassenger.password_hash,
      is_verified: fetchedPassenger.is_verified,
    };
  }

  async retrievePassengerByEmail(passengerEmail: string): Promise<Passenger | null> {
    const fetchedPassenger = await prisma.passenger.findUnique({
      where: { email: passengerEmail },
    });
    if (!fetchedPassenger) return null;
    return {
      id: fetchedPassenger.id,
      name: fetchedPassenger.name,
      email: fetchedPassenger.email,
      phone: fetchedPassenger.phone,
      preferred_ride_type: fetchedPassenger.preferred_ride_type as RideType | null,
      created_at: fetchedPassenger.created_at,
      password_hash: fetchedPassenger.password_hash,
      is_verified: fetchedPassenger.is_verified,
    };
  }

  async registerRideRequest(rideDetails: CreateRideRequest): Promise<RideRequest> {
    const passenger = await prisma.passenger.findUnique({
      where: { id: rideDetails.passenger_id },
    });
    if (!passenger) {
      throw new Error(`Passenger ID ${rideDetails.passenger_id} not found`);
    }
    const createdRideRequest = await prisma.rideRequest.create({
      data: {
        passenger_id: rideDetails.passenger_id,
        ride_type: rideDetails.ride_type,
        pickup_latitude: rideDetails.pickup_latitude,
        pickup_longitude: rideDetails.pickup_longitude,
        pickup_name: rideDetails.pickup_name,
        dropoff_latitude: rideDetails.dropoff_latitude,
        dropoff_longitude: rideDetails.dropoff_longitude,
        dropoff_name: rideDetails.dropoff_name,
        fare: rideDetails.fare,
        status: 'requested',
      },
    });
    return {
      id: createdRideRequest.id,
      passenger_id: createdRideRequest.passenger_id,
      ride_type: createdRideRequest.ride_type as RideType,
      pickup_latitude: createdRideRequest.pickup_latitude,
      pickup_longitude: createdRideRequest.pickup_longitude,
      pickup_name: createdRideRequest.pickup_name,
      dropoff_latitude: createdRideRequest.dropoff_latitude,
      dropoff_longitude: createdRideRequest.dropoff_longitude,
      dropoff_name: createdRideRequest.dropoff_name,
      fare: createdRideRequest.fare,
      status: createdRideRequest.status,
      created_at: createdRideRequest.created_at,
    };
  }

  async retrievePassengerRideHistory(passengerId: string): Promise<RideRequest[]> {
    const passenger = await prisma.passenger.findUnique({
      where: { id: passengerId },
    });
    if (!passenger) {
      throw new Error(`Passenger ID ${passengerId} not found`);
    }
    const rideRequestRecords = await prisma.rideRequest.findMany({
      where: { passenger_id: passengerId },
      orderBy: { created_at: 'desc' },
    });

    const tripServiceUrl = process.env.TRIP_SERVICE_URL || 'http://127.0.0.1:8083';

    const enrichedRideRequests = await Promise.all(
      rideRequestRecords.map(async (rideRequest) => {
        let currentStatus = rideRequest.status;
        let driverName = '';
        let plateNumber = '';

        try {
          const tripResponse = await fetch(`${tripServiceUrl}/rides/${rideRequest.id}`);
          if (tripResponse.ok) {
            const tripDetails = await tripResponse.json() as Record<string, unknown>;
            currentStatus = (tripDetails.status as string) || currentStatus;
            driverName = (tripDetails.driver_name as string) || '';
            plateNumber = (tripDetails.plate_number as string) || '';
          }
        } catch {
          // trip-service unreachable — preserve local status
        }

        return {
          id: rideRequest.id,
          passenger_id: rideRequest.passenger_id,
          ride_type: rideRequest.ride_type as RideType,
          pickup_latitude: rideRequest.pickup_latitude,
          pickup_longitude: rideRequest.pickup_longitude,
          pickup_name: rideRequest.pickup_name,
          dropoff_latitude: rideRequest.dropoff_latitude,
          dropoff_longitude: rideRequest.dropoff_longitude,
          dropoff_name: rideRequest.dropoff_name,
          fare: rideRequest.fare,
          status: currentStatus,
          created_at: rideRequest.created_at,
          driver_name: driverName,
          plate_number: plateNumber,
          password_hash: '',
        };
      }),
    );

    return enrichedRideRequests;
  }

  async updatePassengerProfile({ id, name, phone, email }: UpdatePassengerOptions): Promise<Passenger> {
    const updatedPassenger = await prisma.passenger.update({
      where: { id },
      data: { name, phone, email },
    });
    return {
      id: updatedPassenger.id,
      name: updatedPassenger.name,
      email: updatedPassenger.email,
      phone: updatedPassenger.phone,
      preferred_ride_type: updatedPassenger.preferred_ride_type as RideType | null,
      created_at: updatedPassenger.created_at,
      password_hash: updatedPassenger.password_hash,
      is_verified: updatedPassenger.is_verified,
    };
  }

  async verifyPassengerOtp(passengerEmail: string): Promise<void> {
    await prisma.passenger.update({
      where: { email: passengerEmail },
      data: { is_verified: true },
    });
  }

  async retrievePassengerNotifications(passengerId: string): Promise<any[]> {
    const passenger = await prisma.passenger.findUnique({
      where: { id: passengerId },
    });
    if (!passenger) {
      throw new Error(`Passenger ID ${passengerId} not found`);
    }
    const rideRequests = await prisma.rideRequest.findMany({
      where: { passenger_id: passengerId },
      orderBy: { created_at: 'desc' },
    });

    const notificationsList: any[] = [];
    const tripServiceUrl = process.env.TRIP_SERVICE_URL || 'http://127.0.0.1:8083';

    for (const rideRequest of rideRequests) {
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
      const tripDetails = await response.json();
      if (tripDetails) {
        return {
          status: tripDetails.status || defaultStatus,
          driverName: tripDetails.driver_name || '',
          plateNumber: tripDetails.plate_number || '',
        };
      }
    }
  } catch (error) {
    console.error(`Failed to fetch ride ${rideId} status from trip-service:`, error);
  }
  return {
    status: defaultStatus,
    driverName: '',
    plateNumber: '',
  };
}

function buildNotificationsForRide(
  rideRequest: { id: string; dropoff_name: string; fare: number; created_at: Date },
  tripDetails: TripInfo
): any[] {
  const notificationsList: any[] = [];
  const baseTime = rideRequest.created_at.toISOString();
  const { status, driverName, plateNumber } = tripDetails;

  switch (status) {
    case 'requested':
      notificationsList.push({
        id: `req_${rideRequest.id}`,
        title: 'Finding Driver',
        message: `Your ride request to ${rideRequest.dropoff_name} is active. Finding a driver...`,
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
        message: `You are in transit to ${rideRequest.dropoff_name}.`,
        timestamp: baseTime,
        type: 'ride',
        isRead: false,
      });
      break;

    case 'completed':
      notificationsList.push({
        id: `comp_${rideRequest.id}`,
        title: 'Ride Completed',
        message: `Your trip to ${rideRequest.dropoff_name} is completed. Total fare: ₱${rideRequest.fare.toFixed(2)}`,
        timestamp: baseTime,
        type: 'ride',
        isRead: true,
      });
      break;

    case 'canceled':
      notificationsList.push({
        id: `canc_${rideRequest.id}`,
        title: 'Ride Canceled ❌',
        message: `Your ride to ${rideRequest.dropoff_name} was canceled.`,
        timestamp: baseTime,
        type: 'ride',
        isRead: true,
      });
      break;
  }

  return notificationsList;
}

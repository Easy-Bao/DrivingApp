import { prisma } from '../db.ts';
import { Passenger, RideRequest, RideType } from './types.ts';
import { CreatePassengerRequest, CreateRideRequest } from './schema.ts';
import { PassengerRepository, UpdatePassengerOptions } from './passenger.repository.ts';

export class PrismaPassengerRepository implements PassengerRepository {
  async createPassenger(req: CreatePassengerRequest): Promise<Passenger> {
    const existing = await prisma.passenger.findUnique({
      where: { email: req.email },
    });
    if (existing) {
      throw new Error(`A passenger with email ${req.email} already exists`);
    }
    const passwordHash = await Bun.password.hash(req.password, {
      algorithm: 'bcrypt',
      cost: 10,
    });
    const res = await prisma.passenger.create({
      data: {
        name: req.name,
        email: req.email,
        phone: req.phone,
        preferred_ride_type: req.preferred_ride_type || null,
        password_hash: passwordHash,
      },
    });
    return {
      id: res.id,
      name: res.name,
      email: res.email,
      phone: res.phone,
      preferred_ride_type: res.preferred_ride_type as RideType | null,
      created_at: res.created_at,
      password_hash: res.password_hash,
      is_verified: res.is_verified,
    };
  }

  async getPassenger(id: string): Promise<Passenger | null> {
    const res = await prisma.passenger.findUnique({
      where: { id },
    });
    if (!res) return null;
    return {
      id: res.id,
      name: res.name,
      email: res.email,
      phone: res.phone,
      preferred_ride_type: res.preferred_ride_type as RideType | null,
      created_at: res.created_at,
      password_hash: res.password_hash,
      is_verified: res.is_verified,
    };
  }

  async getPassengerByEmail(email: string): Promise<Passenger | null> {
    const res = await prisma.passenger.findUnique({
      where: { email },
    });
    if (!res) return null;
    return {
      id: res.id,
      name: res.name,
      email: res.email,
      phone: res.phone,
      preferred_ride_type: res.preferred_ride_type as RideType | null,
      created_at: res.created_at,
      password_hash: res.password_hash,
      is_verified: res.is_verified,
    };
  }

  async createRideRequest(req: CreateRideRequest): Promise<RideRequest> {
    const passenger = await prisma.passenger.findUnique({
      where: { id: req.passenger_id },
    });
    if (!passenger) {
      throw new Error(`Passenger ID ${req.passenger_id} not found`);
    }
    const res = await prisma.rideRequest.create({
      data: {
        passenger_id: req.passenger_id,
        ride_type: req.ride_type,
        pickup_latitude: req.pickup_latitude,
        pickup_longitude: req.pickup_longitude,
        pickup_name: req.pickup_name,
        dropoff_latitude: req.dropoff_latitude,
        dropoff_longitude: req.dropoff_longitude,
        dropoff_name: req.dropoff_name,
        fare: req.fare,
        status: 'requested',
      },
    });
    return {
      id: res.id,
      passenger_id: res.passenger_id,
      ride_type: res.ride_type as RideType,
      pickup_latitude: res.pickup_latitude,
      pickup_longitude: res.pickup_longitude,
      pickup_name: res.pickup_name,
      dropoff_latitude: res.dropoff_latitude,
      dropoff_longitude: res.dropoff_longitude,
      dropoff_name: res.dropoff_name,
      fare: res.fare,
      status: res.status,
      created_at: res.created_at,
    };
  }

  async getPassengerRides(passengerId: string): Promise<RideRequest[]> {
    const passenger = await prisma.passenger.findUnique({
      where: { id: passengerId },
    });
    if (!passenger) {
      throw new Error(`Passenger ID ${passengerId} not found`);
    }
    const rows = await prisma.rideRequest.findMany({
      where: { passenger_id: passengerId },
      orderBy: { created_at: 'desc' },
    });

    const tripServiceUrl = process.env.TRIP_SERVICE_URL || 'http://127.0.0.1:8083';

    const enriched = await Promise.all(
      rows.map(async (r) => {
        let status = r.status;
        let driverName = '';
        let plateNumber = '';

        try {
          const tripRes = await fetch(`${tripServiceUrl}/rides/${r.id}`);
          if (tripRes.ok) {
            const trip = await tripRes.json() as Record<string, unknown>;
            status = (trip.status as string) || status;
            driverName = (trip.driver_name as string) || '';
            plateNumber = (trip.plate_number as string) || '';
          }
        } catch {
          // trip-service unreachable — preserve local status
        }

        return {
          id: r.id,
          passenger_id: r.passenger_id,
          ride_type: r.ride_type as RideType,
          pickup_latitude: r.pickup_latitude,
          pickup_longitude: r.pickup_longitude,
          pickup_name: r.pickup_name,
          dropoff_latitude: r.dropoff_latitude,
          dropoff_longitude: r.dropoff_longitude,
          dropoff_name: r.dropoff_name,
          fare: r.fare,
          status,
          created_at: r.created_at,
          driver_name: driverName,
          plate_number: plateNumber,
          password_hash: '',
        };
      }),
    );

    return enriched;
  }

  async updatePassenger({ id, name, phone, email }: UpdatePassengerOptions): Promise<Passenger> {
    const res = await prisma.passenger.update({
      where: { id },
      data: { name, phone, email },
    });
    return {
      id: res.id,
      name: res.name,
      email: res.email,
      phone: res.phone,
      preferred_ride_type: res.preferred_ride_type as RideType | null,
      created_at: res.created_at,
      password_hash: res.password_hash,
      is_verified: res.is_verified,
    };
  }

  async verifyPassenger(email: string): Promise<void> {
    await prisma.passenger.update({
      where: { email },
      data: { is_verified: true },
    });
  }

  async getPassengerNotifications(passengerId: string): Promise<any[]> {
    const passenger = await prisma.passenger.findUnique({
      where: { id: passengerId },
    });
    if (!passenger) {
      throw new Error(`Passenger ID ${passengerId} not found`);
    }
    const rides = await prisma.rideRequest.findMany({
      where: { passenger_id: passengerId },
      orderBy: { created_at: 'desc' },
    });

    const notifications: any[] = [];
    const tripServiceUrl = process.env.TRIP_SERVICE_URL || 'http://127.0.0.1:8083';

    for (const r of rides) {
      const tripInfo = await fetchTripStatus(r.id, r.status, tripServiceUrl);
      notifications.push(...buildNotificationsForRide(r, tripInfo));
    }

    return notifications;
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
      const trip = await response.json();
      if (trip) {
        return {
          status: trip.status || defaultStatus,
          driverName: trip.driver_name || '',
          plateNumber: trip.plate_number || '',
        };
      }
    }
  } catch (err) {
    console.error(`Failed to fetch ride ${rideId} status from trip-service:`, err);
  }
  return {
    status: defaultStatus,
    driverName: '',
    plateNumber: '',
  };
}

function buildNotificationsForRide(
  ride: { id: string; dropoff_name: string; fare: number; created_at: Date },
  tripInfo: TripInfo
): any[] {
  const notifications: any[] = [];
  const baseTime = ride.created_at.toISOString();
  const { status, driverName, plateNumber } = tripInfo;

  switch (status) {
    case 'requested':
      notifications.push({
        id: `req_${ride.id}`,
        title: 'Finding Driver',
        message: `Your ride request to ${ride.dropoff_name} is active. Finding a driver...`,
        timestamp: baseTime,
        type: 'ride',
        isRead: false,
      });
      break;

    case 'accepted':
      notifications.push({
        id: `acc_${ride.id}`,
        title: 'Driver Found!',
        message: `Driver ${driverName || 'Matched Driver'} (${plateNumber || 'Bao Bao'}) has accepted your ride request.`,
        timestamp: baseTime,
        type: 'driver',
        isRead: false,
      });
      notifications.push({
        id: `chat_${ride.id}`,
        title: 'Chat Available',
        message: `You can now chat with your driver, ${driverName || 'your driver'}.`,
        timestamp: baseTime,
        type: 'chat',
        isRead: false,
      });
      break;

    case 'arrived':
      notifications.push({
        id: `arr_${ride.id}`,
        title: 'Driver Arrived',
        message: `Your driver, ${driverName || 'your driver'}, has arrived at your pickup location.`,
        timestamp: baseTime,
        type: 'driver',
        isRead: false,
      });
      break;

    case 'in_transit':
      notifications.push({
        id: `trans_${ride.id}`,
        title: 'Trip Started',
        message: `You are in transit to ${ride.dropoff_name}.`,
        timestamp: baseTime,
        type: 'ride',
        isRead: false,
      });
      break;

    case 'completed':
      notifications.push({
        id: `comp_${ride.id}`,
        title: 'Ride Completed',
        message: `Your trip to ${ride.dropoff_name} is completed. Total fare: ₱${ride.fare.toFixed(2)}`,
        timestamp: baseTime,
        type: 'ride',
        isRead: true,
      });
      break;

    case 'canceled':
      notifications.push({
        id: `canc_${ride.id}`,
        title: 'Ride Canceled ❌',
        message: `Your ride to ${ride.dropoff_name} was canceled.`,
        timestamp: baseTime,
        type: 'ride',
        isRead: true,
      });
      break;
  }

  return notifications;
}

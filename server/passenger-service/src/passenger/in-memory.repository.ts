import { Passenger, RideRequest, RideType } from './types.ts';
import { CreatePassengerRequest, CreateRideRequest } from './schema.ts';
import { PassengerRepository, UpdatePassengerOptions } from './passenger.repository.ts';

export class InMemoryPassengerRepository implements PassengerRepository {
  private passengers = new Map<string, Passenger>();
  private rides = new Map<string, RideRequest[]>();

  async createPassenger(req: CreatePassengerRequest): Promise<Passenger> {
    for (const p of this.passengers.values()) {
      if (p.email === req.email) {
        throw new Error(`A passenger with email ${req.email} already exists`);
      }
    }
    const id = crypto.randomUUID();
    const passwordHash = await Bun.password.hash(req.password, {
      algorithm: 'bcrypt',
      cost: 10,
    });
    const passenger: Passenger = {
      id,
      name: req.name,
      email: req.email,
      phone: req.phone,
      preferred_ride_type: (req.preferred_ride_type as RideType) || null,
      created_at: new Date(),
      password_hash: passwordHash,
      is_verified: false,
    };
    this.passengers.set(id, passenger);
    return passenger;
  }

  async getPassenger(id: string): Promise<Passenger | null> {
    return this.passengers.get(id) || null;
  }

  async getPassengerByEmail(email: string): Promise<Passenger | null> {
    for (const p of this.passengers.values()) {
      if (p.email === email) return p;
    }
    return null;
  }

  async createRideRequest(req: CreateRideRequest): Promise<RideRequest> {
    if (!this.passengers.has(req.passenger_id)) {
      throw new Error(`Passenger ID ${req.passenger_id} not found`);
    }
    const id = crypto.randomUUID();
    const ride: RideRequest = {
      id,
      passenger_id: req.passenger_id,
      ride_type: req.ride_type as RideType,
      pickup_latitude: req.pickup_latitude,
      pickup_longitude: req.pickup_longitude,
      pickup_name: req.pickup_name,
      dropoff_latitude: req.dropoff_latitude,
      dropoff_longitude: req.dropoff_longitude,
      dropoff_name: req.dropoff_name,
      fare: req.fare,
      status: 'requested',
      created_at: new Date(),
    };
    const userRides = this.rides.get(req.passenger_id) || [];
    userRides.push(ride);
    this.rides.set(req.passenger_id, userRides);
    return ride;
  }

  async getPassengerRides(passengerId: string): Promise<RideRequest[]> {
    if (!this.passengers.has(passengerId)) {
      throw new Error(`Passenger ID ${passengerId} not found`);
    }
    return this.rides.get(passengerId) || [];
  }

  async updatePassenger({ id, name, phone, email }: UpdatePassengerOptions): Promise<Passenger> {
    const passenger = this.passengers.get(id);
    if (!passenger) {
      throw new Error(`Passenger ID ${id} not found`);
    }
    const updated: Passenger = { ...passenger, name, phone, email };
    this.passengers.set(id, updated);
    return updated;
  }

  async verifyPassenger(email: string): Promise<void> {
    const passenger = await this.getPassengerByEmail(email);
    if (passenger) passenger.is_verified = true;
  }

  async getPassengerNotifications(passengerId: string): Promise<any[]> {
    const rides = this.rides.get(passengerId) || [];
    const notifications: any[] = [];
    for (const r of rides) {
      const tripInfo: TripInfo = {
        status: r.status,
        driverName: '',
        plateNumber: '',
      };
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

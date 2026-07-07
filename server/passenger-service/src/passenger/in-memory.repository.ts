import { Passenger, RideRequest, RideType } from './types.ts';
import { CreatePassengerRequest, CreateRideRequest } from './schema.ts';
import { PassengerRepository, UpdatePassengerOptions } from './passenger.repository.ts';

export class InMemoryPassengerRepository implements PassengerRepository {
  private passengersMap = new Map<string, Passenger>();
  private ridesMap = new Map<string, RideRequest[]>();

  async registerPassenger(passengerDetails: CreatePassengerRequest): Promise<Passenger> {
    for (const passengerRecord of this.passengersMap.values()) {
      if (passengerRecord.email === passengerDetails.email) {
        throw new Error(`A passenger with email ${passengerDetails.email} already exists`);
      }
    }
    const passengerId = crypto.randomUUID();
    const passwordHash = await Bun.password.hash(passengerDetails.password, {
      algorithm: 'bcrypt',
      cost: 10,
    });
    const passengerRecord: Passenger = {
      id: passengerId,
      name: passengerDetails.name,
      email: passengerDetails.email,
      phone: passengerDetails.phone,
      preferred_ride_type: (passengerDetails.preferred_ride_type as RideType) || null,
      created_at: new Date(),
      password_hash: passwordHash,
      is_verified: false,
    };
    this.passengersMap.set(passengerId, passengerRecord);
    return passengerRecord;
  }

  async retrievePassengerProfile(passengerId: string): Promise<Passenger | null> {
    return this.passengersMap.get(passengerId) || null;
  }

  async retrievePassengerByEmail(passengerEmail: string): Promise<Passenger | null> {
    for (const passengerRecord of this.passengersMap.values()) {
      if (passengerRecord.email === passengerEmail) return passengerRecord;
    }
    return null;
  }

  async registerRideRequest(rideDetails: CreateRideRequest): Promise<RideRequest> {
    if (!this.passengersMap.has(rideDetails.passenger_id)) {
      throw new Error(`Passenger ID ${rideDetails.passenger_id} not found`);
    }
    const rideRequestId = crypto.randomUUID();
    const rideRequestRecord: RideRequest = {
      id: rideRequestId,
      passenger_id: rideDetails.passenger_id,
      ride_type: rideDetails.ride_type as RideType,
      pickup_latitude: rideDetails.pickup_latitude,
      pickup_longitude: rideDetails.pickup_longitude,
      pickup_name: rideDetails.pickup_name,
      dropoff_latitude: rideDetails.dropoff_latitude,
      dropoff_longitude: rideDetails.dropoff_longitude,
      dropoff_name: rideDetails.dropoff_name,
      fare: rideDetails.fare,
      status: 'requested',
      created_at: new Date(),
    };
    const userRidesList = this.ridesMap.get(rideDetails.passenger_id) || [];
    userRidesList.push(rideRequestRecord);
    this.ridesMap.set(rideDetails.passenger_id, userRidesList);
    return rideRequestRecord;
  }

  async retrievePassengerRideHistory(passengerId: string): Promise<RideRequest[]> {
    if (!this.passengersMap.has(passengerId)) {
      throw new Error(`Passenger ID ${passengerId} not found`);
    }
    return this.ridesMap.get(passengerId) || [];
  }

  async updatePassengerProfile({ id, name, phone, email }: UpdatePassengerOptions): Promise<Passenger> {
    const passengerRecord = this.passengersMap.get(id);
    if (!passengerRecord) {
      throw new Error(`Passenger ID ${id} not found`);
    }
    const updatedPassengerRecord: Passenger = { ...passengerRecord, name, phone, email };
    this.passengersMap.set(id, updatedPassengerRecord);
    return updatedPassengerRecord;
  }

  async verifyPassengerOtp(passengerEmail: string): Promise<void> {
    const passengerRecord = await this.retrievePassengerByEmail(passengerEmail);
    if (passengerRecord) passengerRecord.is_verified = true;
  }

  async retrievePassengerNotifications(passengerId: string): Promise<any[]> {
    const rideRequestsList = this.ridesMap.get(passengerId) || [];
    const notificationsList: any[] = [];
    for (const rideRequestRecord of rideRequestsList) {
      const tripDetails: TripInfo = {
        status: rideRequestRecord.status,
        driverName: '',
        plateNumber: '',
      };
      notificationsList.push(...buildNotificationsForRide(rideRequestRecord, tripDetails));
    }
    return notificationsList;
  }
}

interface TripInfo {
  status: string;
  driverName: string;
  plateNumber: string;
}

function buildNotificationsForRide(
  rideRequestRecord: { id: string; dropoff_name: string; fare: number; created_at: Date },
  tripDetails: TripInfo
): any[] {
  const notificationsList: any[] = [];
  const baseTime = rideRequestRecord.created_at.toISOString();
  const { status, driverName, plateNumber } = tripDetails;

  switch (status) {
    case 'requested':
      notificationsList.push({
        id: `req_${rideRequestRecord.id}`,
        title: 'Finding Driver',
        message: `Your ride request to ${rideRequestRecord.dropoff_name} is active. Finding a driver...`,
        timestamp: baseTime,
        type: 'ride',
        isRead: false,
      });
      break;

    case 'accepted':
      notificationsList.push({
        id: `acc_${rideRequestRecord.id}`,
        title: 'Driver Found!',
        message: `Driver ${driverName || 'Matched Driver'} (${plateNumber || 'Bao Bao'}) has accepted your ride request.`,
        timestamp: baseTime,
        type: 'driver',
        isRead: false,
      });
      notificationsList.push({
        id: `chat_${rideRequestRecord.id}`,
        title: 'Chat Available',
        message: `You can now chat with your driver, ${driverName || 'your driver'}.`,
        timestamp: baseTime,
        type: 'chat',
        isRead: false,
      });
      break;

    case 'arrived':
      notificationsList.push({
        id: `arr_${rideRequestRecord.id}`,
        title: 'Driver Arrived',
        message: `Your driver, ${driverName || 'your driver'}, has arrived at your pickup location.`,
        timestamp: baseTime,
        type: 'driver',
        isRead: false,
      });
      break;

    case 'in_transit':
      notificationsList.push({
        id: `trans_${rideRequestRecord.id}`,
        title: 'Trip Started',
        message: `You are in transit to ${rideRequestRecord.dropoff_name}.`,
        timestamp: baseTime,
        type: 'ride',
        isRead: false,
      });
      break;

    case 'completed':
      notificationsList.push({
        id: `comp_${rideRequestRecord.id}`,
        title: 'Ride Completed',
        message: `Your trip to ${rideRequestRecord.dropoff_name} is completed. Total fare: ₱${rideRequestRecord.fare.toFixed(2)}`,
        timestamp: baseTime,
        type: 'ride',
        isRead: true,
      });
      break;

    case 'canceled':
      notificationsList.push({
        id: `canc_${rideRequestRecord.id}`,
        title: 'Ride Canceled ❌',
        message: `Your ride to ${rideRequestRecord.dropoff_name} was canceled.`,
        timestamp: baseTime,
        type: 'ride',
        isRead: true,
      });
      break;
  }

  return notificationsList;
}

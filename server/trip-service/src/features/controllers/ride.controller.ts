import { Context } from 'hono';
import { RideRepositoryImpl } from '../repositories/ride.repository.ts';
import { RideService } from '../services/ride.service.ts';

const rideRepository = new RideRepositoryImpl();
const rideService = new RideService(rideRepository);

function mapRideToSnakeCase(ride: any) {
  if (!ride) return null;
  return {
    id: ride.id,
    passenger_id: ride.passengerId,
    passenger_name: ride.passengerName,
    ride_type: ride.rideType,
    pickup_latitude: ride.pickupLatitude,
    pickup_longitude: ride.pickupLongitude,
    pickup_name: ride.pickupName,
    dropoff_latitude: ride.dropoffLatitude,
    dropoff_longitude: ride.dropoffLongitude,
    dropoff_name: ride.dropoffName,
    fare: ride.fare,
    status: ride.status,
    created_at: ride.createdAt instanceof Date ? ride.createdAt.toISOString() : ride.createdAt,
    completed_at: ride.completedAt instanceof Date ? ride.completedAt.toISOString() : ride.completedAt,
    driver_id: ride.driverId,
    driver_name: ride.driverName,
    driver_rating: ride.driverRating,
    vehicle_type: ride.vehicleType,
    plate_number: ride.plateNumber,
  };
}

export async function handleCreateRide(context: Context) {
  const body = await context.req.json();
  const ride = await rideService.createRideRequest(body);
  return context.json(mapRideToSnakeCase(ride), 201);
}

export async function handleGetActiveRides(context: Context) {
  const ridesList = await rideService.getActiveRideRequests();
  return context.json(ridesList.map(mapRideToSnakeCase));
}

export async function handleGetRideDetails(context: Context) {
  const id = context.req.param('id');
  const ride = await rideService.getRideDetails(id);
  return context.json(mapRideToSnakeCase(ride));
}

export async function handleGetRidesByDriver(context: Context) {
  const driverId = context.req.param('driverId');
  const list = await rideService.getRidesByDriverId(driverId);
  return context.json(list.map(mapRideToSnakeCase));
}

export async function handleGetRidesByPassenger(context: Context) {
  const passengerId = context.req.param('passengerId');
  const list = await rideService.getRidesByPassengerId(passengerId);
  return context.json(list.map(mapRideToSnakeCase));
}

export async function handleAcceptRide(context: Context) {
  const id = context.req.param('id');
  const body = await context.req.json();
  const updated = await rideService.acceptRideRequest(id, body);
  return context.json(mapRideToSnakeCase(updated));
}

export async function handleUpdateRideStatus(context: Context) {
  const id = context.req.param('id');
  const { status } = await context.req.json();
  const updated = await rideService.updateRideStatus(id, status);
  return context.json(mapRideToSnakeCase(updated));
}

export function mapRideToSnakeCase(ride: any) {
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
    driver_id: ride.driverId,
    driver_name: ride.driverName,
    driver_rating: ride.driverRating,
    vehicle_type: ride.vehicleType,
    plate_number: ride.plateNumber,
  };
}

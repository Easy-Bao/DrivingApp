export function mapSession(session: any) {
  return {
    id: session.id,
    passenger_id: session.passengerId,
    ride_type: session.rideType,
    pickup_latitude: session.pickupLatitude,
    pickup_longitude: session.pickupLongitude,
    pickup_name: session.pickupName,
    dropoff_latitude: session.dropoffLatitude,
    dropoff_longitude: session.dropoffLongitude,
    dropoff_name: session.dropoffName,
    distance_km: session.distanceKm,
    duration_minutes: session.durationMinutes,
    offered_fare: session.offeredFare,
    status: session.status,
    accepted_driver_id: session.acceptedDriverId,
    target_driver_id: session.targetDriverId,
    created_at: session.createdAt instanceof Date ? session.createdAt.toISOString() : session.createdAt,
    expires_at: session.expiresAt instanceof Date ? session.expiresAt.toISOString() : session.expiresAt,
  };
}

export function mapOffer(offer: any) {
  return {
    id: offer.id,
    session_id: offer.sessionId,
    driver_id: offer.driverId,
    driver_name: offer.driverName,
    plate_number: offer.plateNumber,
    vehicle_type: offer.vehicleType,
    proposed_fare: offer.proposedFare,
    status: offer.status,
    created_at: offer.createdAt instanceof Date ? offer.createdAt.toISOString() : offer.createdAt,
  };
}

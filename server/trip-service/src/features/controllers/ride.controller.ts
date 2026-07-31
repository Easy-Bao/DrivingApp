import { Context } from 'hono';
import { HTTPException } from 'hono/http-exception';
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
    fare_centavos: ride.fareCentavos,
    commission_rate_basis_points: ride.commissionRateBasisPoints,
    commission_centavos: ride.commissionCentavos,
    assignment_source: ride.assignmentSource,
    assigned_by_admin_id: ride.assignedByAdminId,
    payment_status: ride.paymentStatus,
    pending_status: ride.pendingStatus,
    status_transition_started_at: ride.statusTransitionStartedAt instanceof Date
      ? ride.statusTransitionStartedAt.toISOString()
      : ride.statusTransitionStartedAt,
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
  const body = context.req.valid('json' as never) as Record<string, unknown>;
  const userId = context.get('userId');
  const role = context.get('role');
  if (userId && role !== 'passenger') {
    throw new HTTPException(403, { message: 'FORBIDDEN' });
  }
  const passengerId = userId ?? body.passenger_id;
  if (typeof passengerId !== 'string' || !passengerId) {
    throw new HTTPException(400, { message: 'PASSENGER_ID_REQUIRED' });
  }
  const idempotencyKey = context.req.header('Idempotency-Key');
  if (!userId && !idempotencyKey) {
    throw new HTTPException(400, { message: 'Idempotency-Key header is required' });
  }
  const ride = await rideService.createRideRequest({
    ...body,
    passenger_id: passengerId,
  }, idempotencyKey);
  return context.json(mapRideToSnakeCase(ride), 201);
}

export async function handleGetActiveRides(context: Context) {
  const ridesList = await rideService.getActiveRideRequests();
  return context.json(ridesList.map(mapRideToSnakeCase));
}

export async function handleGetRideDetails(context: Context) {
  const id = context.req.param('id')!;
  const ride = await rideService.getRideDetails(id);
  return context.json(mapRideToSnakeCase(ride));
}

export async function handleGetRidesByDriver(context: Context) {
  const driverId = context.req.param('driverId')!;
  const list = await rideService.getRidesByDriverId(driverId);
  return context.json(list.map(mapRideToSnakeCase));
}

export async function handleGetRidesByPassenger(context: Context) {
  const passengerId = context.req.param('passengerId')!;
  const list = await rideService.getRidesByPassengerId(passengerId);
  return context.json(list.map(mapRideToSnakeCase));
}

export async function handleAcceptRide(context: Context) {
  const id = context.req.param('id')!;
  const body = context.req.valid('json' as never);
  const idempotencyKey = context.req.header('Idempotency-Key');
  if (!idempotencyKey) {
    throw new HTTPException(400, { message: 'Idempotency-Key header is required' });
  }
  const updated = await rideService.acceptRideRequest(id, body, idempotencyKey);
  return context.json(mapRideToSnakeCase(updated));
}

export async function handleUpdateRideStatus(context: Context) {
  const id = context.req.param('id')!;
  const { status } = context.req.valid('json' as never) as { status: string };
  const idempotencyKey = context.req.header('Idempotency-Key');
  if (!idempotencyKey) {
    throw new HTTPException(400, { message: 'Idempotency-Key header is required' });
  }
  const ride = await rideService.getRideDetails(id);
  const userId = context.get('userId');
  const role = context.get('role');
  if (
    userId
    && !(
      (role === 'driver' && ride.driverId === userId)
      || (role === 'passenger' && ride.passengerId === userId && ['canceled', 'cancelled'].includes(status))
    )
  ) {
    throw new HTTPException(403, { message: 'FORBIDDEN' });
  }
  const updated = await rideService.updateRideStatus(id, status, idempotencyKey);
  return context.json(mapRideToSnakeCase(updated));
}

export async function handleGetRideReport(context: Context) {
  const from = context.req.query('from');
  const to = context.req.query('to');
  const rides = await rideService.getRidesForReport({
    status: context.req.query('status'),
    from: from ? new Date(from) : undefined,
    to: to ? new Date(to) : undefined,
  });
  return context.json(rides.map(mapRideToSnakeCase));
}

export async function handleReconcileRideStatuses(context: Context) {
  return context.json(await rideService.reconcilePendingStatusTransitions());
}

/**
 * Service layer orchestrating domain logic for ride requests, matching constraints, and status updates.
 * Cross-service passenger name resolution is delegated to PassengerClient.
 */
import { RideRepository } from '../entities/ride.types.ts';
import { HTTPException } from 'hono/http-exception';
import {
  AdminClient,
  DriverClient,
  FareClient,
  PassengerClient,
} from '../clients/ride.clients.ts';

export class RideService {
  private readonly repository: RideRepository;
  private readonly passengerClient: PassengerClient;
  private readonly driverClient: DriverClient;
  private readonly adminClient: AdminClient;
  private readonly fareClient: FareClient;

  constructor(repository: RideRepository) {
    const passengerServiceUrl = process.env.PASSENGER_SERVICE_URL;
    const driverServiceUrl = process.env.DRIVER_SERVICE_URL;
    const adminServiceUrl = process.env.ADMIN_SERVICE_URL;
    const fareServiceUrl = process.env.FARE_SERVICE_URL;
    if (!passengerServiceUrl) {
      throw new Error('Configuration Error: PASSENGER_SERVICE_URL is required but not set.');
    }
    if (!driverServiceUrl) {
      throw new Error('Configuration Error: DRIVER_SERVICE_URL is required but not set.');
    }
    if (!adminServiceUrl) {
      throw new Error('Configuration Error: ADMIN_SERVICE_URL is required but not set.');
    }
    if (!fareServiceUrl) {
      throw new Error('Configuration Error: FARE_SERVICE_URL is required but not set.');
    }
    this.repository = repository;
    this.passengerClient = new PassengerClient(passengerServiceUrl);
    this.driverClient = new DriverClient(driverServiceUrl);
    this.adminClient = new AdminClient(adminServiceUrl);
    this.fareClient = new FareClient(fareServiceUrl);
  }

  private async ensurePassengerRideAccess(passengerId: string) {
    try {
      await this.passengerClient.checkRideAccess(passengerId);
    } catch (error) {
      const code = error instanceof Error ? error.message : 'PASSENGER_SERVICE_UNAVAILABLE';
      throw new HTTPException(code === 'ACCOUNT_RESTRICTED' ? 403 : 503, {
        message: code === 'ACCOUNT_RESTRICTED'
          ? code
          : 'PASSENGER_SERVICE_UNAVAILABLE',
      });
    }
  }

  private async ensureDriverRideAccess(driverId: string | null) {
    if (!driverId) {
      throw new HTTPException(409, { message: 'DRIVER_NOT_ASSIGNED' });
    }
    try {
      await this.driverClient.checkEligibility(driverId);
    } catch (error) {
      const code = error instanceof Error ? error.message : 'DRIVER_SERVICE_UNAVAILABLE';
      const status = code === 'ACCOUNT_RESTRICTED'
        ? 403
        : ['DRIVER_NOT_APPROVED', 'DRIVER_DOCUMENTS_INCOMPLETE'].includes(code)
          ? 409
          : 503;
      throw new HTTPException(status, {
        message: status === 503 ? 'DRIVER_SERVICE_UNAVAILABLE' : code,
      });
    }
  }

  async createRideRequest(payload: any, idempotencyKey?: string) {
    await this.ensurePassengerRideAccess(payload.passenger_id);
    try {
      await this.adminClient.checkZones({
        pickup_latitude: Number(payload.pickup_latitude),
        pickup_longitude: Number(payload.pickup_longitude),
        dropoff_latitude: Number(payload.dropoff_latitude),
        dropoff_longitude: Number(payload.dropoff_longitude),
      });
    } catch (error) {
      const code = error instanceof Error ? error.message : 'REQUEST_FAILED';
      const status = code === 'ACCOUNT_RESTRICTED' || code === 'OUTSIDE_SERVICE_ZONE'
        || code === 'SERVICE_ZONE_NOT_CONFIGURED'
        ? 403
        : 503;
      throw new HTTPException(status, { message: code });
    }
    const passengerName = await this.passengerClient.fetchPassengerName(payload.passenger_id);
    const requestHash = idempotencyKey
      ? new Bun.CryptoHasher('sha256')
          .update(JSON.stringify(payload))
          .digest('hex')
      : null;
    return await this.repository.createRide({
      ...payload,
      passenger_name: passengerName,
      creation_request_id: idempotencyKey,
      creation_request_hash: requestHash,
    });
  }

  async getRideDetails(id: string) {
    const found = await this.repository.findRideById(id);
    if (!found) {
      throw new HTTPException(404, { message: 'Ride request not found' });
    }
    return found;
  }

  async getActiveRideRequests() {
    return await this.repository.findActiveRides();
  }

  async getRidesByDriverId(driverId: string) {
    return await this.repository.findRidesByDriverId(driverId);
  }

  async getRidesByPassengerId(passengerId: string) {
    return await this.repository.findRidesByPassengerId(passengerId);
  }

  async acceptRideRequest(id: string, driverData: any, idempotencyKey: string) {
    const ride = await this.repository.findRideById(id);
    if (!ride) {
      throw new HTTPException(404, { message: 'Ride request not found' });
    }
    if (ride.status !== 'requested') {
      if (ride.driverId === String(driverData.driver_id)) {
        return ride;
      }
      throw new HTTPException(409, { message: 'Ride already accepted' });
    }
    await this.ensurePassengerRideAccess(ride.passengerId);

    let reservationCreated = false;
    let fareSnapshotCreated = false;
    try {
      const driverId = String(driverData.driver_id);
      const [profile, commissionRateBasisPoints] = await Promise.all([
        this.driverClient.fetchProfile(driverId),
        this.adminClient.currentCommission(),
      ]);
      const fareCentavos = ride.fareCentavos ?? Math.round(ride.fare * 100);
      const reserved = await this.driverClient.reserve({
        driverId,
        rideId: id,
        fareCentavos,
        commissionBasisPoints: commissionRateBasisPoints,
        idempotencyKey: `${idempotencyKey}:credit`,
      });
      reservationCreated = true;
      const assignmentSource = driverData.assignment_source === 'admin'
        ? 'admin'
        : 'driver_offer';
      await this.fareClient.recordSnapshot({
        rideId: id,
        driverId: profile.id,
        serviceType: ride.rideType,
        totalFareCentavos: fareCentavos,
        commissionRateBasisPoints,
        commissionCentavos: reserved.commissionCentavos,
        assignmentSource,
        idempotencyKey: `${idempotencyKey}:fare`,
      });
      fareSnapshotCreated = true;
      return await this.repository.acceptRideTransaction(id, {
        driver_id: profile.id,
        driver_name: profile.name,
        driver_rating: profile.rating?.toString() ?? '5.0',
        vehicle_type: profile.vehicleType ?? profile.vehicle_type ?? 'BaoBao',
        plate_number: profile.plateNumber ?? profile.plate_number ?? 'Unknown',
        commission_rate_basis_points: commissionRateBasisPoints,
        commission_centavos: reserved.commissionCentavos,
        credit_reservation_id: reserved.reservation.id,
        assignment_source: assignmentSource,
        assigned_by_admin_id: driverData.assigned_by_admin_id ?? null,
      });
    } catch (error: any) {
      if (reservationCreated) {
        await this.driverClient.updateReservation(
          id,
          'release',
          `${idempotencyKey}:rollback`,
          'Trip assignment rolled back',
        ).catch(() => undefined);
      }
      if (fareSnapshotCreated) {
        await this.fareClient.updatePaymentStatus(
          id,
          'canceled',
          `${idempotencyKey}:fare-rollback`,
        ).catch(() => undefined);
      }
      if (error.message === 'Driver Max Cap Reached') {
        throw new HTTPException(400, {
          message: 'Driver has reached the maximum cap of 5 concurrent accepted ride requests',
        });
      }
      if (
        error.message === 'Driver has active priority' ||
        error.message === 'Cannot accept priority with active rides'
      ) {
        throw new HTTPException(400, { message: 'Priority Ride constraints violated' });
      }
      if (error.message === 'Ride not found') {
        throw new HTTPException(404, { message: 'Ride request not found' });
      }
      const status = error.message === 'INSUFFICIENT_CREDIT'
        || error.message === 'DRIVER_NOT_APPROVED'
        || error.message === 'ACCOUNT_RESTRICTED'
        ? 409
        : 400;
      throw new HTTPException(status, { message: error.message });
    }
  }

  async updateRideStatus(id: string, requestedStatus: string, idempotencyKey: string) {
    const ride = await this.repository.findRideById(id);
    if (!ride) {
      throw new HTTPException(404, { message: 'Ride request not found' });
    }
    const status = requestedStatus === 'cancelled' ? 'canceled' : requestedStatus;
    if (ride.status === status && !ride.pendingStatus) {
      return ride;
    }
    if (ride.pendingStatus && ride.pendingStatus !== status) {
      throw new HTTPException(409, { message: 'STATUS_TRANSITION_IN_PROGRESS' });
    }
    const allowedTransitions: Record<string, string[]> = {
      requested: ['canceled'],
      accepted: ['arrived', 'canceled'],
      arrived: ['in_transit', 'canceled'],
      in_transit: ['completed', 'payment_disputed'],
      payment_disputed: ['completed', 'canceled'],
    };
    if (!ride.pendingStatus && !allowedTransitions[ride.status]?.includes(status)) {
      throw new HTTPException(409, {
        message: `INVALID_RIDE_STATUS_TRANSITION:${ride.status}:${status}`,
      });
    }
    if (['arrived', 'in_transit'].includes(status) && !ride.pendingStatus) {
      await this.ensureDriverRideAccess(ride.driverId);
      if (status === 'in_transit') {
        await this.ensurePassengerRideAccess(ride.passengerId);
      }
    }

    const transition = ride.pendingStatus
      ? ride
      : await this.repository.beginStatusTransition(id, status, idempotencyKey);
    const operationKey = transition.statusRequestId ?? idempotencyKey;
    let paymentStatus: string | undefined;
    if (ride.creditReservationId) {
      if (status === 'completed') {
        await this.driverClient.updateReservation(
          id,
          'settle',
          `${operationKey}:settle`,
          'Cash ride completed',
        );
        paymentStatus = 'cash_received';
      } else if (status === 'canceled') {
        await this.driverClient.updateReservation(
          id,
          'release',
          `${operationKey}:release`,
          'Ride canceled',
        );
        paymentStatus = 'canceled';
      } else if (status === 'payment_disputed') {
        await this.driverClient.updateReservation(
          id,
          'dispute',
          `${operationKey}:dispute`,
          'Driver reported unpaid cash ride',
        );
        paymentStatus = 'cash_disputed';
      }
    }
    if (paymentStatus) {
      await this.fareClient.updatePaymentStatus(
        id,
        paymentStatus as 'cash_received' | 'cash_disputed' | 'canceled',
        `${operationKey}:fare-status`,
      );
    }
    const isTerminalStatus = status === 'completed' || status === 'canceled';
    return await this.repository.completeStatusTransition(
      id,
      status,
      isTerminalStatus ? new Date() : undefined,
      paymentStatus,
    );
  }

  /**
   * Replays status transitions that were durably started before a downstream
   * or local database failure interrupted the settlement saga.
   */
  async reconcilePendingStatusTransitions() {
    const pending = await this.repository.findPendingStatusTransitions();
    const results: Array<Record<string, unknown>> = [];
    for (const ride of pending) {
      try {
        const reconciled = await this.updateRideStatus(
          ride.id,
          ride.pendingStatus!,
          ride.statusRequestId!,
        );
        results.push({ ride_id: ride.id, status: reconciled.status, outcome: 'succeeded' });
      } catch (error) {
        results.push({
          ride_id: ride.id,
          pending_status: ride.pendingStatus,
          outcome: 'failed',
          error: error instanceof Error ? error.message : 'Unknown error',
        });
      }
    }
    return {
      processed: results.length,
      results,
      reconciled_at: new Date().toISOString(),
    };
  }

  async getRidesForReport(input: {
    status?: string;
    from?: Date;
    to?: Date;
  }) {
    return await this.repository.findRidesForReport(input);
  }
}

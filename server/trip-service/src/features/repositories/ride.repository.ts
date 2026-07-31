import { db } from '../../shared/drizzle.ts';
import { rides } from '../../db/schema.ts';
import { eq, desc, and, gte, inArray, isNotNull, isNull, lte } from 'drizzle-orm';
import { Ride, RideRepository } from '../entities/ride.types.ts';

export class RideRepositoryImpl implements RideRepository {
  async createRide(details: any): Promise<Ride> {
    const values = {
      id: crypto.randomUUID(),
      passengerId: details.passenger_id,
      passengerName: details.passenger_name || null,
      rideType: details.ride_type || 'solo-ride',
      pickupLatitude: details.pickup_latitude,
      pickupLongitude: details.pickup_longitude,
      pickupName: details.pickup_name,
      dropoffLatitude: details.dropoff_latitude,
      dropoffLongitude: details.dropoff_longitude,
      dropoffName: details.dropoff_name,
      fare: details.fare,
      fareCentavos: details.fare_centavos ?? Math.round(details.fare * 100),
      assignmentSource: details.assignment_source ?? 'driver_offer',
      assignedByAdminId: details.assigned_by_admin_id ?? null,
      status: 'requested',
      creationRequestId: details.creation_request_id ?? null,
      creationRequestHash: details.creation_request_hash ?? null,
    };
    const insert = db.insert(rides)
      .values({
        ...values,
      })
      .$dynamic();
    const [created] = details.creation_request_id
      ? await insert
          .onConflictDoNothing({ target: rides.creationRequestId })
          .returning()
      : await insert.returning();
    if (created) return created;

    const [existing] = await db.select()
      .from(rides)
      .where(eq(rides.creationRequestId, details.creation_request_id))
      .limit(1);
    if (!existing || existing.creationRequestHash !== details.creation_request_hash) {
      throw new Error('IDEMPOTENCY_KEY_REUSED');
    }
    return existing;
  }

  async findRideById(id: string): Promise<Ride | null> {
    const [matched] = await db.select().from(rides).where(eq(rides.id, id));
    return matched || null;
  }

  async findActiveRides(): Promise<Ride[]> {
    return await db.select()
      .from(rides)
      .where(inArray(rides.status, [
        'requested',
        'accepted',
        'arrived',
        'in_transit',
        'payment_disputed',
      ]));
  }

  async findRidesByDriverId(driverId: string): Promise<Ride[]> {
    return await db.select()
      .from(rides)
      .where(eq(rides.driverId, driverId))
      .orderBy(desc(rides.createdAt));
  }

  async findRidesByPassengerId(passengerId: string): Promise<Ride[]> {
    return await db.select()
      .from(rides)
      .where(eq(rides.passengerId, passengerId))
      .orderBy(desc(rides.createdAt));
  }

  async acceptRideTransaction(id: string, driverData: any): Promise<Ride> {
    const {
      driver_id,
      driver_name,
      driver_rating,
      vehicle_type,
      plate_number,
      commission_rate_basis_points,
      commission_centavos,
      credit_reservation_id,
      assignment_source,
      assigned_by_admin_id,
    } = driverData;

    return await db.transaction(async (tx) => {
      const activeRides = await tx.select()
        .from(rides)
        .where(
          and(
            eq(rides.driverId, driver_id),
            inArray(rides.status, ['accepted', 'arrived', 'in_transit'])
          )
        );

      if (activeRides.length >= 5) {
        throw new Error("Driver Max Cap Reached");
      }

      const hasActivePriority = activeRides.some((r) => r.rideType === 'Bao Premium');
      if (hasActivePriority) {
        throw new Error("Driver has active priority");
      }

      const targetRideList = await tx.select().from(rides).where(eq(rides.id, id));
      const targetRide = targetRideList[0];
      if (!targetRide) {
        throw new Error("Ride not found");
      }

      if (targetRide.status !== 'requested') {
        throw new Error("Ride already accepted");
      }

      if (targetRide.rideType === 'Bao Premium' && activeRides.length > 0) {
        throw new Error("Cannot accept priority with active rides");
      }

      const [updated] = await tx.update(rides)
        .set({
          status: 'accepted',
          driverId: driver_id,
          driverName: driver_name,
          driverRating: driver_rating ?? '5.0',
          vehicleType: vehicle_type ?? 'Unknown',
          plateNumber: plate_number ?? 'Unknown',
          commissionRateBasisPoints: commission_rate_basis_points,
          commissionCentavos: commission_centavos,
          creditReservationId: credit_reservation_id,
          assignmentSource: assignment_source ?? targetRide.assignmentSource,
          assignedByAdminId: assigned_by_admin_id ?? targetRide.assignedByAdminId,
          updatedAt: new Date(),
        })
        .where(and(eq(rides.id, id), eq(rides.status, 'requested')))
        .returning();

      if (!updated) {
        const [current] = await tx.select()
          .from(rides)
          .where(eq(rides.id, id))
          .limit(1);
        if (current?.driverId === driver_id && current.status !== 'requested') {
          return current;
        }
        throw new Error('Ride already accepted');
      }
      return updated;
    });
  }

  async beginStatusTransition(
    id: string,
    status: string,
    requestId: string,
  ): Promise<Ride> {
    const [updated] = await db.update(rides)
      .set({
        pendingStatus: status,
        statusRequestId: requestId,
        statusTransitionStartedAt: new Date(),
        updatedAt: new Date(),
      })
      .where(and(eq(rides.id, id), isNull(rides.pendingStatus)))
      .returning();
    if (updated) return updated;

    const current = await this.findRideById(id);
    if (current?.pendingStatus === status) return current;
    throw new Error(current ? 'STATUS_TRANSITION_IN_PROGRESS' : 'Ride not found');
  }

  async completeStatusTransition(
    id: string,
    status: string,
    completedAt?: Date,
    paymentStatus?: string,
  ): Promise<Ride> {
    const updateValues: any = {
      status,
      pendingStatus: null,
      statusRequestId: null,
      statusTransitionStartedAt: null,
      updatedAt: new Date(),
    };
    if (completedAt) {
      updateValues.completedAt = completedAt;
    }
    if (paymentStatus) {
      updateValues.paymentStatus = paymentStatus;
    }

    const [updated] = await db.update(rides)
      .set(updateValues)
      .where(and(eq(rides.id, id), eq(rides.pendingStatus, status)))
      .returning();

    if (!updated) {
      const current = await this.findRideById(id);
      if (current?.status === status && !current.pendingStatus) return current;
      throw new Error('Ride status transition could not be completed');
    }
    return updated;
  }

  async findPendingStatusTransitions(): Promise<Ride[]> {
    return await db.select()
      .from(rides)
      .where(isNotNull(rides.pendingStatus))
      .orderBy(rides.statusTransitionStartedAt);
  }

  async findRidesForReport(input: {
    status?: string;
    from?: Date;
    to?: Date;
  }): Promise<Ride[]> {
    const conditions = [
      input.status ? eq(rides.status, input.status) : undefined,
      input.from ? gte(rides.createdAt, input.from) : undefined,
      input.to ? lte(rides.createdAt, input.to) : undefined,
    ].filter(Boolean);
    return await db.select()
      .from(rides)
      .where(conditions.length > 0 ? and(...conditions as any[]) : undefined)
      .orderBy(desc(rides.createdAt));
  }
}

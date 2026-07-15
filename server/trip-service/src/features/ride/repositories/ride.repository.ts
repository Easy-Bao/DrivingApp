/**
 * Repository layer executing Drizzle queries and transaction locks for rides table.
 */
import { db } from '../../../shared/drizzle.ts';
import { rides } from '../../../db/schema.ts';
import { eq, desc, and, inArray } from 'drizzle-orm';
import { Ride, RideRepository } from '../entities/ride.types.ts';

export class DrizzleRideRepository implements RideRepository {
  async createRide(details: any): Promise<Ride> {
    const [created] = await db.insert(rides)
      .values({
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
        status: 'requested',
      })
      .returning();
    return created;
  }

  async findRideById(id: string): Promise<Ride | null> {
    const [matched] = await db.select().from(rides).where(eq(rides.id, id));
    return matched || null;
  }

  async findActiveRides(): Promise<Ride[]> {
    return await db.select().from(rides).where(eq(rides.status, 'requested'));
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
    const { driver_id, driver_name, driver_rating, vehicle_type, plate_number } = driverData;

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
        })
        .where(eq(rides.id, id))
        .returning();

      return updated;
    });
  }

  async updateRideStatus(id: string, status: string, completedAt?: Date): Promise<Ride> {
    const updateValues: any = { status };
    if (completedAt) {
      updateValues.completedAt = completedAt;
    }

    const [updated] = await db.update(rides)
      .set(updateValues)
      .where(eq(rides.id, id))
      .returning();

    if (!updated) {
      throw new Error("Ride not found");
    }
    return updated;
  }
}

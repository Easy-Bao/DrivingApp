import { prisma } from '../db.ts';

export async function acceptRideRequest(id: string, driverData: any) {
  const { driver_id, driver_name, driver_rating, vehicle_type, plate_number } = driverData;

  return await prisma.$transaction(async (tx) => {
    const activeRides = await tx.ride.findMany({
      where: {
        driverId: driver_id,
        status: { in: ['accepted', 'arrived', 'in_transit'] },
      },
    });

    if (activeRides.length >= 5) {
      throw new Error("Driver Max Cap Reached");
    }

    const hasActivePriority = activeRides.some((r) => r.rideType === 'Bao Premium');
    if (hasActivePriority) {
      throw new Error("Driver has active priority");
    }

    const targetRide = await tx.ride.findUnique({ where: { id } });
    if (!targetRide) {
      throw new Error("Ride not found")
    }

    if (targetRide.rideType === 'Bao Premium' && activeRides.length > 0) {
      throw new Error("Cannot accept priority with active rides");
    }

    return await tx.ride.update({
      where: { id },
      data: {
        status: 'accepted',
        driverId: driver_id,
        driverName: driver_name,
        driverRating: driver_rating ?? '5.0',
        vehicleType: vehicle_type ?? 'Unknown',
        plateNumber: plate_number ?? 'Unknown',
      },
    });
  });
}

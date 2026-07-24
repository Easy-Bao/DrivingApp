import { pgTable, text, timestamp, uuid, doublePrecision } from 'drizzle-orm/pg-core';

export const rides = pgTable('rides', {
  id: text('id').primaryKey(),
  passengerId: text('passenger_id').notNull(),
  passengerName: text('passenger_name'),
  rideType: text('ride_type').notNull(),
  pickupLatitude: doublePrecision('pickup_latitude').notNull(),
  pickupLongitude: doublePrecision('pickup_longitude').notNull(),
  pickupName: text('pickup_name').notNull(),
  dropoffLatitude: doublePrecision('dropoff_latitude').notNull(),
  dropoffLongitude: doublePrecision('dropoff_longitude').notNull(),
  dropoffName: text('dropoff_name').notNull(),
  fare: doublePrecision('fare').notNull(),
  status: text('status').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' }).defaultNow().notNull(),
  completedAt: timestamp('completed_at', { withTimezone: true, mode: 'date' }),
  driverId: text('driver_id'),
  driverName: text('driver_name'),
  driverRating: text('driver_rating'),
  vehicleType: text('vehicle_type'),
  plateNumber: text('plate_number'),
});

import { pgTable, text, timestamp, uuid, doublePrecision } from 'drizzle-orm/pg-core';

export const bidSessions = pgTable('bid_sessions', {
  id: uuid('id').primaryKey(),
  passengerId: uuid('passenger_id').notNull(),
  rideType: text('ride_type').notNull(),
  pickupLatitude: doublePrecision('pickup_latitude').notNull(),
  pickupLongitude: doublePrecision('pickup_longitude').notNull(),
  pickupName: text('pickup_name').notNull(),
  dropoffLatitude: doublePrecision('dropoff_latitude').notNull(),
  dropoffLongitude: doublePrecision('dropoff_longitude').notNull(),
  dropoffName: text('dropoff_name').notNull(),
  distanceKm: doublePrecision('distance_km').notNull(),
  durationMinutes: doublePrecision('duration_minutes').notNull(),
  offeredFare: doublePrecision('offered_fare').notNull(),
  status: text('status').default('open').notNull(),
  acceptedDriverId: text('accepted_driver_id'),
  targetDriverId: text('target_driver_id'),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' }).defaultNow().notNull(),
  expiresAt: timestamp('expires_at', { withTimezone: true, mode: 'date' }).notNull(),
});

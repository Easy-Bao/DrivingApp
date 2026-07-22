import { pgTable, text, timestamp, uuid, doublePrecision } from 'drizzle-orm/pg-core';
import { passengers } from './passengers.schema.ts';

export const rideRequests = pgTable('ride_requests', {
  id: uuid('id').defaultRandom().primaryKey(),
  passengerId: uuid('passenger_id').references(() => passengers.id).notNull(),
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
});

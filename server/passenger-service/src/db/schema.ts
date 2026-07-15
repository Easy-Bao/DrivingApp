/**
 * Database schema defining the passengers and ride requests tables for Drizzle ORM.
 */
import { pgTable, text, timestamp, boolean, uuid, doublePrecision } from 'drizzle-orm/pg-core';

export const passengers = pgTable('passengers', {
  id: uuid('id').defaultRandom().primaryKey(),
  name: text('name').notNull(),
  email: text('email').unique().notNull(),
  phone: text('phone').notNull(),
  preferredRideType: text('preferred_ride_type'),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' }).defaultNow().notNull(),
  passwordHash: text('password_hash').default('').notNull(),
  isVerified: boolean('is_verified').default(false).notNull(),
});

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

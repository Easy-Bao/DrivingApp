import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import { pgTable, text, timestamp, boolean, doublePrecision } from 'drizzle-orm/pg-core';

const passengerDbUrl = process.env.PASSENGER_DB_URL;
if (!passengerDbUrl || passengerDbUrl.trim().length === 0) {
  throw new Error('Security Configuration Error: PASSENGER_DB_URL environment variable is missing.');
}

const driverDbUrl = process.env.DRIVER_DB_URL;
if (!driverDbUrl || driverDbUrl.trim().length === 0) {
  throw new Error('Security Configuration Error: DRIVER_DB_URL environment variable is missing.');
}

const passengerPgClient = postgres(passengerDbUrl);
const driverPgClient = postgres(driverDbUrl);

export const passengersTable = pgTable('passengers', {
  id: text('id').primaryKey(),
  name: text('name').notNull(),
  email: text('email').unique().notNull(),
  phone: text('phone').notNull(),
  preferredRideType: text('preferred_ride_type'),
  passwordHash: text('password_hash').notNull(),
  isVerified: boolean('is_verified').default(false).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' })
    .defaultNow()
    .notNull(),
});

export const driversTable = pgTable('drivers', {
  id: text('id').primaryKey(),
  name: text('name').notNull(),
  email: text('email').unique().notNull(),
  phone: text('phone').notNull(),
  vehicleType: text('vehicle_type').notNull(),
  plateNumber: text('plate_number').notNull(),
  passwordHash: text('password_hash').notNull(),
  rating: doublePrecision('rating').default(5.0).notNull(),
  isOnline: boolean('is_online').default(false).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' })
    .defaultNow()
    .notNull(),
});

export const passengerDb = drizzle(passengerPgClient);
export const driverDb = drizzle(driverPgClient);

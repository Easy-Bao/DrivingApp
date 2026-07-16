import { pgTable, text, timestamp, boolean, uuid, doublePrecision } from 'drizzle-orm/pg-core';

export const drivers = pgTable('drivers', {
  id: uuid('id').primaryKey(),
  name: text('name').notNull(),
  email: text('email').unique().notNull(),
  phone: text('phone').notNull(),
  vehicleType: text('vehicle_type').notNull(),
  plateNumber: text('plate_number').notNull(),
  passwordHash: text('password_hash').notNull(),
  rating: doublePrecision('rating').default(5.0).notNull(),
  isOnline: boolean('is_online').default(false).notNull(),
  lat: doublePrecision('lat').default(7.828282).notNull(),
  lng: doublePrecision('lng').default(123.434343).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' }).defaultNow().notNull(),
});

export const reviews = pgTable('reviews', {
  id: uuid('id').primaryKey(),
  driverId: uuid('driver_id').references(() => drivers.id).notNull(),
  passengerName: text('passenger_name').notNull(),
  rating: doublePrecision('rating').notNull(),
  comment: text('comment').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' }).defaultNow().notNull(),
});

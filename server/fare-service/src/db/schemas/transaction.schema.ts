import { pgTable, uuid, text, doublePrecision, timestamp } from 'drizzle-orm/pg-core';

export const fareTransactions = pgTable('fare_transactions', {
  id: uuid('id').defaultRandom().primaryKey(),
  rideId: text('ride_id').notNull(),
  serviceType: text('service_type').notNull(),
  distanceKm: doublePrecision('distance_km').notNull(),
  durationMinutes: doublePrecision('duration_minutes').notNull(),
  baseFare: doublePrecision('base_fare').notNull(),
  distanceCharge: doublePrecision('distance_charge').notNull(),
  timeCharge: doublePrecision('time_charge').notNull(),
  surgeCharge: doublePrecision('surge_charge').notNull(),
  totalFare: doublePrecision('total_fare').notNull(),
  driverEarnings: doublePrecision('driver_earnings').notNull(),
  platformFee: doublePrecision('platform_fee').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

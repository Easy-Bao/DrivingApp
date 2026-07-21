import { pgTable, uuid, text, doublePrecision, boolean, timestamp } from 'drizzle-orm/pg-core';

export const servicePricingRules = pgTable('service_pricing_rules', {
  id: uuid('id').defaultRandom().primaryKey(),
  serviceType: text('service_type').notNull().unique(),
  baseFare: doublePrecision('base_fare').notNull(),
  perKmRate: doublePrecision('per_km_rate').notNull(),
  perMinuteRate: doublePrecision('per_minute_rate').notNull().default(1.5),
  minimumFare: doublePrecision('minimum_fare').notNull().default(25.0),
  surgeMultiplier: doublePrecision('surge_multiplier').notNull().default(1.0),
  isActive: boolean('is_active').notNull().default(true),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

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

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

export const ratingPricingConfigs = pgTable('rating_pricing_configs', {
  id: uuid('id').defaultRandom().primaryKey(),
  configKey: text('config_key').notNull().unique().default('default'),
  minimumRatingThreshold: doublePrecision('minimum_rating_threshold').notNull().default(4.5),
  highRatingBonusMultiplier: doublePrecision('high_rating_bonus_multiplier').notNull().default(1.05),
  lowRatingSurgePenaltyMultiplier: doublePrecision('low_rating_surge_penalty_multiplier').notNull().default(1.0),
  baseSurgeCap: doublePrecision('base_surge_cap').notNull().default(2.5),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

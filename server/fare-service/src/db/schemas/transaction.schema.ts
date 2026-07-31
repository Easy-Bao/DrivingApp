import { sql } from 'drizzle-orm';
import {
  check,
  pgTable,
  uuid,
  text,
  doublePrecision,
  integer,
  timestamp,
  uniqueIndex,
} from 'drizzle-orm/pg-core';

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
  driverId: text('driver_id'),
  totalFareCentavos: integer('total_fare_centavos'),
  driverEarningsCentavos: integer('driver_earnings_centavos'),
  platformFeeCentavos: integer('platform_fee_centavos'),
  commissionRateBasisPoints: integer('commission_rate_basis_points'),
  assignmentSource: text('assignment_source').notNull().default('driver_offer'),
  paymentStatus: text('payment_status').notNull().default('cash_pending'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => ({
  rideIdUnique: uniqueIndex('fare_transactions_ride_id_unique').on(table.rideId),
  // Legacy rows can have an unknown rate; every rate-bearing snapshot must be exact.
  snapshotIntegrity: check(
    'fare_transactions_snapshot_integrity',
    sql`${table.commissionRateBasisPoints} IS NULL OR (
      ${table.totalFareCentavos} IS NOT NULL
      AND ${table.driverEarningsCentavos} IS NOT NULL
      AND ${table.platformFeeCentavos} IS NOT NULL
      AND ${table.totalFareCentavos} >= 0
      AND ${table.driverEarningsCentavos} >= 0
      AND ${table.platformFeeCentavos} >= 0
      AND ${table.commissionRateBasisPoints} BETWEEN 0 AND 10000
      AND ${table.totalFareCentavos}::bigint =
        ${table.driverEarningsCentavos}::bigint + ${table.platformFeeCentavos}::bigint
      AND ${table.platformFeeCentavos} = (
        (${table.totalFareCentavos}::bigint * ${table.commissionRateBasisPoints} + 5000)
        / 10000
      )::integer
    )`,
  ),
  assignmentSourceAllowed: check(
    'fare_transactions_assignment_source_allowed',
    sql`${table.assignmentSource} IN ('driver_offer', 'admin')`,
  ),
  paymentStatusAllowed: check(
    'fare_transactions_payment_status_allowed',
    sql`${table.paymentStatus} IN ('cash_pending', 'cash_received', 'cash_disputed', 'canceled')`,
  ),
}));

import { sql } from 'drizzle-orm';
import {
  boolean,
  check,
  integer,
  jsonb,
  pgTable,
  primaryKey,
  text,
  timestamp,
  uniqueIndex,
} from 'drizzle-orm/pg-core';
import { drivers } from './drivers.schema.ts';

export type DocumentCheckStatus = 'pending' | 'verified' | 'rejected' | 'expired';
export type RestrictionStatus = 'active' | 'lifted';
export type TopupRequestStatus = 'pending' | 'approved' | 'rejected';
export type CreditReservationStatus = 'reserved' | 'settled' | 'released' | 'disputed';
export type CreditLedgerType =
  | 'topup'
  | 'adjustment'
  | 'refund'
  | 'reserve'
  | 'settle'
  | 'release'
  | 'dispute';

export const driverDocumentRequirements = pgTable(
  'driver_document_requirements',
  {
    id: text('id').primaryKey(),
    name: text('name').notNull(),
    normalizedName: text('normalized_name').notNull(),
    isActive: boolean('is_active').default(true).notNull(),
    requiresExpiry: boolean('requires_expiry').default(false).notNull(),
    createdBy: text('created_by').notNull(),
    createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true, mode: 'date' })
      .defaultNow()
      .notNull(),
  },
  (table) => ({
    normalizedNameUnique: uniqueIndex('driver_document_requirements_normalized_name_unique')
      .on(table.normalizedName),
  }),
);

export const driverDocumentChecks = pgTable(
  'driver_document_checks',
  {
    id: text('id').primaryKey(),
    driverId: text('driver_id')
      .references(() => drivers.id, { onDelete: 'cascade' })
      .notNull(),
    requirementId: text('requirement_id')
      .references(() => driverDocumentRequirements.id, { onDelete: 'cascade' })
      .notNull(),
    status: text('status')
      .$type<DocumentCheckStatus>()
      .default('pending')
      .notNull(),
    expiresAt: timestamp('expires_at', { withTimezone: true, mode: 'date' }),
    notes: text('notes'),
    reviewedBy: text('reviewed_by'),
    reviewedAt: timestamp('reviewed_at', { withTimezone: true, mode: 'date' }),
    createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true, mode: 'date' })
      .defaultNow()
      .notNull(),
  },
  (table) => ({
    driverRequirementUnique: uniqueIndex('driver_document_checks_driver_requirement_unique')
      .on(table.driverId, table.requirementId),
  }),
);

export const driverAccountRestrictions = pgTable(
  'driver_account_restrictions',
  {
    id: text('id').primaryKey(),
    driverId: text('driver_id')
      .references(() => drivers.id, { onDelete: 'cascade' })
      .notNull(),
    status: text('status')
      .$type<RestrictionStatus>()
      .default('active')
      .notNull(),
    reason: text('reason').notNull(),
    expiresAt: timestamp('expires_at', { withTimezone: true, mode: 'date' }),
    createdBy: text('created_by').notNull(),
    createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' })
      .defaultNow()
      .notNull(),
    liftedBy: text('lifted_by'),
    liftedReason: text('lifted_reason'),
    liftedAt: timestamp('lifted_at', { withTimezone: true, mode: 'date' }),
  },
  (table) => ({
    driverIndex: uniqueIndex('driver_account_restrictions_active_unique')
      .on(table.driverId)
      .where(sql`${table.status} = 'active'`),
  }),
);

export const driverCreditWallets = pgTable(
  'driver_credit_wallets',
  {
    driverId: text('driver_id')
      .primaryKey()
      .references(() => drivers.id, { onDelete: 'cascade' }),
    balanceCentavos: integer('balance_centavos').default(0).notNull(),
    reservedCentavos: integer('reserved_centavos').default(0).notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true, mode: 'date' })
      .defaultNow()
      .notNull(),
  },
  (table) => ({
    balanceNonnegative: check(
      'driver_credit_wallets_balance_nonnegative',
      sql`${table.balanceCentavos} >= 0`,
    ),
    reservedNonnegative: check(
      'driver_credit_wallets_reserved_nonnegative',
      sql`${table.reservedCentavos} >= 0`,
    ),
    reservationCovered: check(
      'driver_credit_wallets_reservation_covered',
      sql`${table.balanceCentavos} >= ${table.reservedCentavos}`,
    ),
  }),
);

export const driverTopupChannels = pgTable(
  'driver_topup_channels',
  {
    id: text('id').primaryKey(),
    name: text('name').notNull(),
    accountName: text('account_name').notNull(),
    accountReference: text('account_reference').notNull(),
    instructions: text('instructions'),
    isActive: boolean('is_active').default(true).notNull(),
    createdBy: text('created_by').notNull(),
    createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true, mode: 'date' })
      .defaultNow()
      .notNull(),
  },
);

export const driverTopupRequests = pgTable(
  'driver_topup_requests',
  {
    id: text('id').primaryKey(),
    driverId: text('driver_id')
      .references(() => drivers.id, { onDelete: 'cascade' })
      .notNull(),
    channelId: text('channel_id')
      .references(() => driverTopupChannels.id)
      .notNull(),
    amountCentavos: integer('amount_centavos').notNull(),
    senderName: text('sender_name').notNull(),
    transactionReference: text('transaction_reference').notNull(),
    normalizedTransactionReference: text('normalized_transaction_reference').notNull(),
    status: text('status')
      .$type<TopupRequestStatus>()
      .default('pending')
      .notNull(),
    submittedAt: timestamp('submitted_at', { withTimezone: true, mode: 'date' })
      .defaultNow()
      .notNull(),
    reviewedBy: text('reviewed_by'),
    reviewedAt: timestamp('reviewed_at', { withTimezone: true, mode: 'date' }),
    reviewReason: text('review_reason'),
  },
  (table) => ({
    channelReferenceUnique: uniqueIndex('driver_topup_requests_channel_reference_unique')
      .on(table.channelId, table.normalizedTransactionReference),
    amountPositive: check(
      'driver_topup_requests_amount_positive',
      sql`${table.amountCentavos} > 0`,
    ),
  }),
);

export const driverCreditReservations = pgTable(
  'driver_credit_reservations',
  {
    id: text('id').primaryKey(),
    driverId: text('driver_id')
      .references(() => drivers.id, { onDelete: 'cascade' })
      .notNull(),
    rideId: text('ride_id').notNull(),
    fareCentavos: integer('fare_centavos').notNull(),
    commissionBasisPoints: integer('commission_basis_points').notNull(),
    commissionCentavos: integer('commission_centavos').notNull(),
    status: text('status')
      .$type<CreditReservationStatus>()
      .default('reserved')
      .notNull(),
    disputeReason: text('dispute_reason'),
    createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true, mode: 'date' })
      .defaultNow()
      .notNull(),
  },
  (table) => ({
    rideUnique: uniqueIndex('driver_credit_reservations_ride_unique').on(table.rideId),
    fareNonnegative: check(
      'driver_credit_reservations_fare_nonnegative',
      sql`${table.fareCentavos} >= 0`,
    ),
    commissionPositive: check(
      'driver_credit_reservations_commission_positive',
      sql`${table.commissionCentavos} >= 0`,
    ),
    basisPointsRange: check(
      'driver_credit_reservations_basis_points_range',
      sql`${table.commissionBasisPoints} BETWEEN 0 AND 10000`,
    ),
  }),
);

export const driverCreditLedger = pgTable(
  'driver_credit_ledger',
  {
    id: text('id').primaryKey(),
    driverId: text('driver_id')
      .references(() => drivers.id, { onDelete: 'cascade' })
      .notNull(),
    type: text('type').$type<CreditLedgerType>().notNull(),
    balanceDeltaCentavos: integer('balance_delta_centavos').notNull(),
    reservedDeltaCentavos: integer('reserved_delta_centavos').notNull(),
    balanceAfterCentavos: integer('balance_after_centavos').notNull(),
    reservedAfterCentavos: integer('reserved_after_centavos').notNull(),
    rideId: text('ride_id'),
    topupRequestId: text('topup_request_id')
      .references(() => driverTopupRequests.id),
    actorId: text('actor_id').notNull(),
    reason: text('reason').notNull(),
    createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' })
      .defaultNow()
      .notNull(),
  },
);

export const driverIdempotencyRecords = pgTable(
  'driver_idempotency_records',
  {
    operation: text('operation').notNull(),
    idempotencyKey: text('idempotency_key').notNull(),
    requestHash: text('request_hash').notNull(),
    responseJson: jsonb('response_json').$type<unknown>().notNull(),
    createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' })
      .defaultNow()
      .notNull(),
  },
  (table) => ({
    primaryKey: primaryKey({
      columns: [table.operation, table.idempotencyKey],
      name: 'driver_idempotency_records_primary_key',
    }),
  }),
);

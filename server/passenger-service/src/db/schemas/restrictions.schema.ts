import {
  pgTable,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from 'drizzle-orm/pg-core';
import { passengers } from './passengers.schema.ts';

export const passengerRestrictions = pgTable('passenger_restrictions', {
  id: uuid('id').defaultRandom().primaryKey(),
  passengerId: text('passenger_id')
    .references(() => passengers.id)
    .notNull(),
  caseId: text('case_id'),
  reason: text('reason').notNull(),
  endsAt: timestamp('ends_at', { withTimezone: true, mode: 'date' }),
  revokedAt: timestamp('revoked_at', { withTimezone: true, mode: 'date' }),
  createdBy: text('created_by').notNull(),
  idempotencyKey: text('idempotency_key').notNull(),
  requestHash: text('request_hash'),
  liftedBy: text('lifted_by'),
  liftReason: text('lift_reason'),
  liftIdempotencyKey: text('lift_idempotency_key'),
  liftRequestHash: text('lift_request_hash'),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' })
    .defaultNow()
    .notNull(),
}, (table) => ({
  idempotencyUnique: uniqueIndex('passenger_restrictions_idempotency_unique')
    .on(table.idempotencyKey),
  liftIdempotencyUnique: uniqueIndex('passenger_restrictions_lift_idempotency_unique')
    .on(table.liftIdempotencyKey),
}));

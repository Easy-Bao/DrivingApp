import {
  index,
  integer,
  jsonb,
  pgEnum,
  pgTable,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from 'drizzle-orm/pg-core';

export const CASE_TARGET_TYPES = ['ride', 'driver', 'passenger'] as const;
export const CASE_STATUSES = [
  'open',
  'under_review',
  'resolved',
  'dismissed',
] as const;
export const AUDIT_OUTCOMES = ['succeeded', 'failed'] as const;

export type CaseTargetType = typeof CASE_TARGET_TYPES[number];
export type CaseStatus = typeof CASE_STATUSES[number];
export type AuditOutcome = typeof AUDIT_OUTCOMES[number];

export const caseTargetTypeEnum = pgEnum('case_target_type', CASE_TARGET_TYPES);
export const caseStatusEnum = pgEnum('case_status', CASE_STATUSES);
export const auditOutcomeEnum = pgEnum('audit_outcome', AUDIT_OUTCOMES);

export const adminOwners = pgTable('admin_owners', {
  id: uuid('id').defaultRandom().primaryKey(),
  email: text('email').notNull(),
  passwordHash: text('password_hash').notNull(),
  failedAttempts: integer('failed_attempts').notNull().default(0),
  lockedUntil: timestamp('locked_until', { withTimezone: true, mode: 'date' }),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' })
    .defaultNow()
    .notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true, mode: 'date' })
    .defaultNow()
    .notNull(),
}, (table) => ({
  emailUnique: uniqueIndex('admin_owners_email_unique').on(table.email),
}));

export const adminAuditEvents = pgTable('admin_audit_events', {
  id: uuid('id').defaultRandom().primaryKey(),
  actorAdminId: text('actor_admin_id').notNull(),
  action: text('action').notNull(),
  targetType: text('target_type').notNull(),
  targetId: text('target_id'),
  reason: text('reason'),
  beforeState: jsonb('before_state'),
  afterState: jsonb('after_state'),
  outcome: auditOutcomeEnum('outcome').notNull(),
  requestId: text('request_id').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' })
    .defaultNow()
    .notNull(),
}, (table) => ({
  requestIdIndex: index('admin_audit_events_request_id_idx').on(table.requestId),
}));

export const adminMutationResults = pgTable('admin_mutation_results', {
  requestId: text('request_id').primaryKey(),
  action: text('action').notNull(),
  targetType: text('target_type').notNull(),
  targetId: text('target_id'),
  requestHash: text('request_hash').notNull(),
  response: jsonb('response').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' })
    .defaultNow()
    .notNull(),
});

export const complaintCases = pgTable('complaint_cases', {
  id: uuid('id').defaultRandom().primaryKey(),
  targetType: caseTargetTypeEnum('target_type').notNull(),
  targetId: text('target_id').notNull(),
  rideId: text('ride_id'),
  category: text('category').notNull(),
  notes: text('notes').notNull(),
  status: caseStatusEnum('status').notNull().default('open'),
  resolution: text('resolution'),
  createdBy: text('created_by').notNull(),
  resolvedAt: timestamp('resolved_at', { withTimezone: true, mode: 'date' }),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' })
    .defaultNow()
    .notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true, mode: 'date' })
    .defaultNow()
    .notNull(),
}, (table) => ({
  statusCreatedAtIndex: index('complaint_cases_status_created_at_idx')
    .on(table.status, table.createdAt),
}));

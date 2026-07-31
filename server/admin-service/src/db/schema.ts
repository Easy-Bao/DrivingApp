import {
  boolean,
  integer,
  index,
  jsonb,
  pgTable,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from 'drizzle-orm/pg-core';

export const adminAuditEvents = pgTable('admin_audit_events', {
  id: uuid('id').defaultRandom().primaryKey(),
  actorAdminId: text('actor_admin_id').notNull(),
  action: text('action').notNull(),
  targetType: text('target_type').notNull(),
  targetId: text('target_id'),
  reason: text('reason'),
  beforeState: jsonb('before_state'),
  afterState: jsonb('after_state'),
  outcome: text('outcome').notNull(),
  requestId: text('request_id').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' })
    .defaultNow()
    .notNull(),
}, (table) => ({
  requestIdIndex: index('admin_audit_events_request_id_idx')
    .on(table.requestId),
}));

export const adminMutationResults = pgTable('admin_mutation_results', {
  requestId: text('request_id').primaryKey(),
  action: text('action').notNull(),
  response: jsonb('response').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' })
    .defaultNow()
    .notNull(),
});

export const complaintCases = pgTable('complaint_cases', {
  id: uuid('id').defaultRandom().primaryKey(),
  targetType: text('target_type').notNull(),
  targetId: text('target_id').notNull(),
  rideId: text('ride_id'),
  category: text('category').notNull(),
  notes: text('notes').notNull(),
  status: text('status').notNull().default('open'),
  resolution: text('resolution'),
  restrictionId: text('restriction_id'),
  createdBy: text('created_by').notNull(),
  resolvedAt: timestamp('resolved_at', { withTimezone: true, mode: 'date' }),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' })
    .defaultNow()
    .notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true, mode: 'date' })
    .defaultNow()
    .notNull(),
});

export const serviceZones = pgTable('service_zones', {
  psgcCode: text('psgc_code').primaryKey(),
  correspondenceCode: text('correspondence_code').notNull().unique(),
  name: text('name').notNull(),
  isActive: boolean('is_active').notNull().default(false),
  geometry: jsonb('geometry'),
  sourceName: text('source_name').notNull(),
  sourceUrl: text('source_url').notNull(),
  sourceDate: text('source_date'),
  sourceLicense: text('source_license').notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true, mode: 'date' })
    .defaultNow()
    .notNull(),
});

export const commissionPolicies = pgTable('commission_policies', {
  id: uuid('id').defaultRandom().primaryKey(),
  rateBasisPoints: integer('rate_basis_points').notNull(),
  effectiveAt: timestamp('effective_at', { withTimezone: true, mode: 'date' })
    .notNull(),
  createdBy: text('created_by').notNull(),
  reason: text('reason').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' })
    .defaultNow()
    .notNull(),
});

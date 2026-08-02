import {
  index,
  pgEnum,
  pgTable,
  text,
  timestamp,
  uuid,
} from 'drizzle-orm/pg-core';

export const CASE_TARGET_TYPES = ['ride', 'driver', 'passenger'] as const;
export const CASE_STATUSES = [
  'open',
  'under_review',
  'resolved',
  'dismissed',
] as const;

export type CaseTargetType = typeof CASE_TARGET_TYPES[number];
export type CaseStatus = typeof CASE_STATUSES[number];

export const caseTargetTypeEnum = pgEnum('case_target_type', CASE_TARGET_TYPES);
export const caseStatusEnum = pgEnum('case_status', CASE_STATUSES);

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

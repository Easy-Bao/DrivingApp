import {
  index,
  jsonb,
  pgEnum,
  pgTable,
  text,
  timestamp,
  uuid,
} from 'drizzle-orm/pg-core';

export const AUDIT_OUTCOMES = ['succeeded', 'failed'] as const;
export const ADMIN_ACTIONS = ['case.create', 'case.update'] as const;
export const ADMIN_TARGET_TYPES = ['case'] as const;

export type AuditOutcome = typeof AUDIT_OUTCOMES[number];
export type AdminAction = typeof ADMIN_ACTIONS[number];
export type AdminTargetType = typeof ADMIN_TARGET_TYPES[number];

export const auditOutcomeEnum = pgEnum('audit_outcome', AUDIT_OUTCOMES);

export const adminAuditEvents = pgTable('admin_audit_events', {
  id: uuid('id').defaultRandom().primaryKey(),
  actorAdminId: text('actor_admin_id').notNull(),
  action: text('action').$type<AdminAction>().notNull(),
  targetType: text('target_type').$type<AdminTargetType>().notNull(),
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
  action: text('action').$type<AdminAction>().notNull(),
  targetType: text('target_type').$type<AdminTargetType>().notNull(),
  targetId: text('target_id'),
  requestHash: text('request_hash').notNull(),
  response: jsonb('response').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' })
    .defaultNow()
    .notNull(),
});

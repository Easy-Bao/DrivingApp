import { sql } from 'drizzle-orm';
import { boolean, check, integer, pgTable, text, timestamp } from 'drizzle-orm/pg-core';

/**
 * The boolean primary key is deliberately constant so PostgreSQL enforces one owner row.
 */
export const adminAuthAccounts = pgTable(
  'admin_auth_accounts',
  {
    singletonKey: boolean('singleton_key').primaryKey().default(true),
    id: text('id').unique().notNull(),
    email: text('email').unique().notNull(),
    passwordHash: text('password_hash').notNull(),
    failedLoginAttempts: integer('failed_login_attempts').default(0).notNull(),
    lockedUntil: timestamp('locked_until', { withTimezone: true, mode: 'date' }),
    createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true, mode: 'date' })
      .defaultNow()
      .notNull(),
  },
  (table) => [
    check('admin_auth_accounts_singleton_key_check', sql`${table.singletonKey} = true`),
    check(
      'admin_auth_accounts_failed_login_attempts_check',
      sql`${table.failedLoginAttempts} >= 0`,
    ),
  ],
);

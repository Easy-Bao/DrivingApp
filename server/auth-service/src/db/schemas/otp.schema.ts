import { pgTable, text, timestamp, boolean, uuid } from 'drizzle-orm/pg-core';
import { userAuthAccounts } from './users.schema.ts';

export const otpTokens = pgTable('otp_tokens', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').references(() => userAuthAccounts.id).notNull(),
  email: text('email').notNull(),
  codeHash: text('code_hash').notNull(),
  isUsed: boolean('is_used').default(false).notNull(),
  expiresAt: timestamp('expires_at', { withTimezone: true, mode: 'date' }).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' }).defaultNow().notNull(),
});

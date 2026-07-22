import { pgTable, text, timestamp, boolean, uuid } from 'drizzle-orm/pg-core';

export const passengers = pgTable('passengers', {
  id: uuid('id').defaultRandom().primaryKey(),
  name: text('name').notNull(),
  email: text('email').unique().notNull(),
  phone: text('phone').notNull(),
  preferredRideType: text('preferred_ride_type'),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' }).defaultNow().notNull(),
  passwordHash: text('password_hash').default('').notNull(),
  isVerified: boolean('is_verified').default(false).notNull(),
});

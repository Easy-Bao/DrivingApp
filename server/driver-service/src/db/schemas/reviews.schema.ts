import { pgTable, text, timestamp, uuid, doublePrecision } from 'drizzle-orm/pg-core';
import { drivers } from './drivers.schema.ts';

export const reviews = pgTable('reviews', {
  id: uuid('id').primaryKey(),
  driverId: uuid('driver_id').references(() => drivers.id).notNull(),
  passengerName: text('passenger_name').notNull(),
  rating: doublePrecision('rating').notNull(),
  comment: text('comment').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' }).defaultNow().notNull(),
});

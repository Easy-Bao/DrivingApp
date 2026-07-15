/**
 * Database schema defining the rooms and messages tables for Drizzle ORM in chat-service.
 */
import { pgTable, text, timestamp, boolean, uuid, varchar } from 'drizzle-orm/pg-core';

export const rooms = pgTable('rooms', {
  id: varchar('id', { length: 255 }).primaryKey(),
  driverId: text('driver_id').notNull(),
  passengerId: text('passenger_id').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' }).defaultNow().notNull(),
  resolved: boolean('resolved').default(false).notNull(),
});

export const messages = pgTable('messages', {
  id: uuid('id').defaultRandom().primaryKey(),
  roomId: varchar('room_id', { length: 255 }).references(() => rooms.id, { onDelete: 'cascade' }).notNull(),
  senderId: text('sender_id').notNull(),
  message: text('message').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' }).defaultNow().notNull(),
});

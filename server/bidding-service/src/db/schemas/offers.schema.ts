import { pgTable, text, timestamp, uuid, doublePrecision } from 'drizzle-orm/pg-core';
import { bidSessions } from './bids.schema.ts';

export const driverOffers = pgTable('driver_offers', {
  id: text('id').primaryKey(),
  sessionId: text('session_id').references(() => bidSessions.id, { onDelete: 'cascade' }).notNull(),
  driverId: text('driver_id').notNull(),
  driverName: text('driver_name').notNull(),
  plateNumber: text('plate_number').notNull(),
  vehicleType: text('vehicle_type').notNull(),
  proposedFare: doublePrecision('proposed_fare').notNull(),
  status: text('status').default('pending').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' }).defaultNow().notNull(),
});

import { pgTable, text, timestamp, boolean, doublePrecision } from 'drizzle-orm/pg-core';

export type DriverApprovalStatus = 'pending' | 'approved' | 'rejected';

export const drivers = pgTable('drivers', {
  id: text('id').primaryKey(),
  name: text('name').notNull(),
  email: text('email').unique().notNull(),
  phone: text('phone').notNull(),
  vehicleType: text('vehicle_type').notNull(),
  plateNumber: text('plate_number').notNull(),
  passwordHash: text('password_hash').notNull(),
  rating: doublePrecision('rating').default(5.0).notNull(),
  isOnline: boolean('is_online').default(false).notNull(),
  isVerified: boolean('is_verified').default(false).notNull(),
  lat: doublePrecision('lat').default(7.828282).notNull(),
  lng: doublePrecision('lng').default(123.434343).notNull(),
  approvalStatus: text('approval_status')
    .$type<DriverApprovalStatus>()
    .default('pending')
    .notNull(),
  approvalReason: text('approval_reason'),
  approvalReviewedBy: text('approval_reviewed_by'),
  approvalReviewedAt: timestamp('approval_reviewed_at', { withTimezone: true, mode: 'date' }),
  createdAt: timestamp('created_at', { withTimezone: true, mode: 'date' }).defaultNow().notNull(),
});

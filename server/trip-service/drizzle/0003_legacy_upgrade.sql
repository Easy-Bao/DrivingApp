-- Upgrade the pre-admin-MVP rides table without db:push or destructive rewrites.
ALTER TABLE "rides" ADD COLUMN IF NOT EXISTS "fare_centavos" integer;
--> statement-breakpoint
ALTER TABLE "rides" ADD COLUMN IF NOT EXISTS "commission_rate_basis_points" integer;
--> statement-breakpoint
ALTER TABLE "rides" ADD COLUMN IF NOT EXISTS "commission_centavos" integer;
--> statement-breakpoint
ALTER TABLE "rides" ADD COLUMN IF NOT EXISTS "credit_reservation_id" text;
--> statement-breakpoint
ALTER TABLE "rides" ADD COLUMN IF NOT EXISTS "assignment_source" text DEFAULT 'driver_offer' NOT NULL;
--> statement-breakpoint
ALTER TABLE "rides" ADD COLUMN IF NOT EXISTS "assigned_by_admin_id" text;
--> statement-breakpoint
ALTER TABLE "rides" ADD COLUMN IF NOT EXISTS "payment_status" text DEFAULT 'cash_pending' NOT NULL;
--> statement-breakpoint
ALTER TABLE "rides" ADD COLUMN IF NOT EXISTS "updated_at" timestamp with time zone DEFAULT now() NOT NULL;
--> statement-breakpoint
UPDATE "rides"
SET "fare_centavos" = round("fare" * 100)::integer
WHERE "fare_centavos" IS NULL;

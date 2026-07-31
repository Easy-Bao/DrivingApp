-- Upgrade the pre-admin-MVP fare ledger while retaining historical rows.
ALTER TABLE "fare_transactions" ADD COLUMN IF NOT EXISTS "driver_id" text;
--> statement-breakpoint
ALTER TABLE "fare_transactions" ADD COLUMN IF NOT EXISTS "total_fare_centavos" integer;
--> statement-breakpoint
ALTER TABLE "fare_transactions" ADD COLUMN IF NOT EXISTS "driver_earnings_centavos" integer;
--> statement-breakpoint
ALTER TABLE "fare_transactions" ADD COLUMN IF NOT EXISTS "platform_fee_centavos" integer;
--> statement-breakpoint
ALTER TABLE "fare_transactions" ADD COLUMN IF NOT EXISTS "commission_rate_basis_points" integer;
--> statement-breakpoint
ALTER TABLE "fare_transactions" ADD COLUMN IF NOT EXISTS "payment_status" text DEFAULT 'cash_pending' NOT NULL;
--> statement-breakpoint
UPDATE "fare_transactions"
SET
  "total_fare_centavos" = round("total_fare" * 100)::integer,
  "driver_earnings_centavos" = round("driver_earnings" * 100)::integer,
  "platform_fee_centavos" = round("platform_fee" * 100)::integer
WHERE
  "total_fare_centavos" IS NULL
  OR "driver_earnings_centavos" IS NULL
  OR "platform_fee_centavos" IS NULL;

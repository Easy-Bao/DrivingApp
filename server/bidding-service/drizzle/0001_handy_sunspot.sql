ALTER TABLE "bid_sessions" ADD COLUMN IF NOT EXISTS "offered_fare_centavos" integer;
--> statement-breakpoint
UPDATE "bid_sessions"
SET "offered_fare_centavos" = round("offered_fare" * 100)::integer
WHERE "offered_fare_centavos" IS NULL;
--> statement-breakpoint
ALTER TABLE "bid_sessions" ALTER COLUMN "offered_fare_centavos" SET NOT NULL;
--> statement-breakpoint
ALTER TABLE "driver_offers" ADD COLUMN IF NOT EXISTS "proposed_fare_centavos" integer;
--> statement-breakpoint
UPDATE "driver_offers"
SET "proposed_fare_centavos" = round("proposed_fare" * 100)::integer
WHERE "proposed_fare_centavos" IS NULL;
--> statement-breakpoint
ALTER TABLE "driver_offers" ALTER COLUMN "proposed_fare_centavos" SET NOT NULL;

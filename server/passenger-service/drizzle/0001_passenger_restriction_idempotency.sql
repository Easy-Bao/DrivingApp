ALTER TABLE "passenger_restrictions" ADD COLUMN "request_hash" text;--> statement-breakpoint
ALTER TABLE "passenger_restrictions" ADD COLUMN "lifted_by" text;--> statement-breakpoint
ALTER TABLE "passenger_restrictions" ADD COLUMN "lift_reason" text;--> statement-breakpoint
ALTER TABLE "passenger_restrictions" ADD COLUMN "lift_idempotency_key" text;--> statement-breakpoint
ALTER TABLE "passenger_restrictions" ADD COLUMN "lift_request_hash" text;--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "passenger_restrictions_lift_idempotency_unique" ON "passenger_restrictions" ("lift_idempotency_key");
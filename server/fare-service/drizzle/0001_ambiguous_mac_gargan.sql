ALTER TABLE "fare_transactions" ALTER COLUMN "created_at" SET DATA TYPE timestamp with time zone;--> statement-breakpoint
ALTER TABLE "fare_transactions" ADD COLUMN "assignment_source" text DEFAULT 'driver_offer' NOT NULL;--> statement-breakpoint
ALTER TABLE "fare_transactions" ADD COLUMN "updated_at" timestamp with time zone DEFAULT now() NOT NULL;
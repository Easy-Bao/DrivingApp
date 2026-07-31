CREATE TABLE IF NOT EXISTS "bid_sessions" (
	"id" text PRIMARY KEY NOT NULL,
	"passenger_id" text NOT NULL,
	"ride_type" text NOT NULL,
	"pickup_latitude" double precision NOT NULL,
	"pickup_longitude" double precision NOT NULL,
	"pickup_name" text NOT NULL,
	"dropoff_latitude" double precision NOT NULL,
	"dropoff_longitude" double precision NOT NULL,
	"dropoff_name" text NOT NULL,
	"distance_km" double precision NOT NULL,
	"duration_minutes" double precision NOT NULL,
	"offered_fare" double precision NOT NULL,
	"status" text DEFAULT 'open' NOT NULL,
	"accepted_driver_id" text,
	"accepted_offer_id" text,
	"accepted_trip_id" text,
	"acceptance_idempotency_key" text,
	"assignment_source" text,
	"assigned_by_admin_id" text,
	"target_driver_id" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"expires_at" timestamp with time zone NOT NULL
);
--> statement-breakpoint
ALTER TABLE "bid_sessions" ADD COLUMN IF NOT EXISTS "accepted_offer_id" text;
--> statement-breakpoint
ALTER TABLE "bid_sessions" ADD COLUMN IF NOT EXISTS "accepted_trip_id" text;
--> statement-breakpoint
ALTER TABLE "bid_sessions" ADD COLUMN IF NOT EXISTS "acceptance_idempotency_key" text;
--> statement-breakpoint
ALTER TABLE "bid_sessions" ADD COLUMN IF NOT EXISTS "assignment_source" text;
--> statement-breakpoint
ALTER TABLE "bid_sessions" ADD COLUMN IF NOT EXISTS "assigned_by_admin_id" text;
--> statement-breakpoint
ALTER TABLE "bid_sessions" ADD COLUMN IF NOT EXISTS "updated_at" timestamp with time zone DEFAULT now() NOT NULL;
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "driver_offers" (
	"id" text PRIMARY KEY NOT NULL,
	"session_id" text NOT NULL,
	"driver_id" text NOT NULL,
	"driver_name" text NOT NULL,
	"plate_number" text NOT NULL,
	"vehicle_type" text NOT NULL,
	"proposed_fare" double precision NOT NULL,
	"status" text DEFAULT 'pending' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "driver_offers" ADD CONSTRAINT "driver_offers_session_id_bid_sessions_id_fk" FOREIGN KEY ("session_id") REFERENCES "public"."bid_sessions"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS "passengers" (
	"id" text PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"email" text NOT NULL,
	"phone" text NOT NULL,
	"preferred_ride_type" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"password_hash" text DEFAULT '' NOT NULL,
	"is_verified" boolean DEFAULT false NOT NULL,
	CONSTRAINT "passengers_email_unique" UNIQUE("email")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "ride_requests" (
	"id" text PRIMARY KEY NOT NULL,
	"passenger_id" text NOT NULL,
	"ride_type" text NOT NULL,
	"pickup_latitude" double precision NOT NULL,
	"pickup_longitude" double precision NOT NULL,
	"pickup_name" text NOT NULL,
	"dropoff_latitude" double precision NOT NULL,
	"dropoff_longitude" double precision NOT NULL,
	"dropoff_name" text NOT NULL,
	"fare" double precision NOT NULL,
	"status" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "passenger_restrictions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"passenger_id" text NOT NULL,
	"case_id" text,
	"reason" text NOT NULL,
	"ends_at" timestamp with time zone,
	"revoked_at" timestamp with time zone,
	"created_by" text NOT NULL,
	"idempotency_key" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "ride_requests" ADD CONSTRAINT "ride_requests_passenger_id_passengers_id_fk" FOREIGN KEY ("passenger_id") REFERENCES "public"."passengers"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "passenger_restrictions" ADD CONSTRAINT "passenger_restrictions_passenger_id_passengers_id_fk" FOREIGN KEY ("passenger_id") REFERENCES "public"."passengers"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "passenger_restrictions_idempotency_unique" ON "passenger_restrictions" ("idempotency_key");
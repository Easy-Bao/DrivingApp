CREATE TABLE IF NOT EXISTS "rating_pricing_configs" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"config_key" text DEFAULT 'default' NOT NULL,
	"minimum_rating_threshold" double precision DEFAULT 4.5 NOT NULL,
	"high_rating_bonus_multiplier" double precision DEFAULT 1.05 NOT NULL,
	"low_rating_surge_penalty_multiplier" double precision DEFAULT 1 NOT NULL,
	"base_surge_cap" double precision DEFAULT 2.5 NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "rating_pricing_configs_config_key_unique" UNIQUE("config_key")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "service_pricing_rules" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"service_type" text NOT NULL,
	"base_fare" double precision NOT NULL,
	"per_km_rate" double precision NOT NULL,
	"per_minute_rate" double precision DEFAULT 1.5 NOT NULL,
	"minimum_fare" double precision DEFAULT 25 NOT NULL,
	"surge_multiplier" double precision DEFAULT 1 NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "service_pricing_rules_service_type_unique" UNIQUE("service_type")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "fare_transactions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"ride_id" text NOT NULL,
	"service_type" text NOT NULL,
	"distance_km" double precision NOT NULL,
	"duration_minutes" double precision NOT NULL,
	"base_fare" double precision NOT NULL,
	"distance_charge" double precision NOT NULL,
	"time_charge" double precision NOT NULL,
	"surge_charge" double precision NOT NULL,
	"total_fare" double precision NOT NULL,
	"driver_earnings" double precision NOT NULL,
	"platform_fee" double precision NOT NULL,
	"driver_id" text,
	"total_fare_centavos" integer,
	"driver_earnings_centavos" integer,
	"platform_fee_centavos" integer,
	"commission_rate_basis_points" integer,
	"payment_status" text DEFAULT 'cash_pending' NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "fare_transactions_ride_id_unique" ON "fare_transactions" ("ride_id");
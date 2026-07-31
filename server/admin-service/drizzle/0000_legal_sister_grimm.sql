CREATE TABLE "admin_audit_events" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"actor_admin_id" text NOT NULL,
	"action" text NOT NULL,
	"target_type" text NOT NULL,
	"target_id" text,
	"reason" text,
	"before_state" jsonb,
	"after_state" jsonb,
	"outcome" text NOT NULL,
	"request_id" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "commission_policies" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"rate_basis_points" integer NOT NULL,
	"effective_at" timestamp with time zone NOT NULL,
	"created_by" text NOT NULL,
	"reason" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "complaint_cases" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"target_type" text NOT NULL,
	"target_id" text NOT NULL,
	"ride_id" text,
	"category" text NOT NULL,
	"notes" text NOT NULL,
	"status" text DEFAULT 'open' NOT NULL,
	"resolution" text,
	"restriction_id" text,
	"created_by" text NOT NULL,
	"resolved_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "service_zones" (
	"psgc_code" text PRIMARY KEY NOT NULL,
	"correspondence_code" text NOT NULL,
	"name" text NOT NULL,
	"is_active" boolean DEFAULT false NOT NULL,
	"geometry" jsonb,
	"source_name" text NOT NULL,
	"source_url" text NOT NULL,
	"source_date" text,
	"source_license" text NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "service_zones_correspondence_code_unique" UNIQUE("correspondence_code")
);
--> statement-breakpoint
CREATE UNIQUE INDEX "admin_audit_events_request_id_unique" ON "admin_audit_events" USING btree ("request_id");
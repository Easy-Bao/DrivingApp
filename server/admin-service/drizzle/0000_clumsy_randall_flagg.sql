CREATE TYPE "public"."audit_outcome" AS ENUM('succeeded', 'failed');--> statement-breakpoint
CREATE TYPE "public"."case_status" AS ENUM('open', 'under_review', 'resolved', 'dismissed');--> statement-breakpoint
CREATE TYPE "public"."case_target_type" AS ENUM('ride', 'driver', 'passenger');--> statement-breakpoint
CREATE TABLE "admin_audit_events" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"actor_admin_id" text NOT NULL,
	"action" text NOT NULL,
	"target_type" text NOT NULL,
	"target_id" text,
	"reason" text,
	"before_state" jsonb,
	"after_state" jsonb,
	"outcome" "audit_outcome" NOT NULL,
	"request_id" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "admin_mutation_results" (
	"request_id" text PRIMARY KEY NOT NULL,
	"action" text NOT NULL,
	"target_type" text NOT NULL,
	"target_id" text,
	"request_hash" text NOT NULL,
	"response" jsonb NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "admin_owners" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"email" text NOT NULL,
	"password_hash" text NOT NULL,
	"failed_attempts" integer DEFAULT 0 NOT NULL,
	"locked_until" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "complaint_cases" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"target_type" "case_target_type" NOT NULL,
	"target_id" text NOT NULL,
	"ride_id" text,
	"category" text NOT NULL,
	"notes" text NOT NULL,
	"status" "case_status" DEFAULT 'open' NOT NULL,
	"resolution" text,
	"created_by" text NOT NULL,
	"resolved_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE INDEX "admin_audit_events_request_id_idx" ON "admin_audit_events" USING btree ("request_id");--> statement-breakpoint
CREATE UNIQUE INDEX "admin_owners_email_unique" ON "admin_owners" USING btree ("email");--> statement-breakpoint
CREATE INDEX "complaint_cases_status_created_at_idx" ON "complaint_cases" USING btree ("status","created_at");
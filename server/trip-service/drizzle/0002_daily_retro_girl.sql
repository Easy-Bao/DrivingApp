ALTER TABLE "rides" ADD COLUMN "pending_status" text;--> statement-breakpoint
ALTER TABLE "rides" ADD COLUMN "status_request_id" text;--> statement-breakpoint
ALTER TABLE "rides" ADD COLUMN "status_transition_started_at" timestamp with time zone;
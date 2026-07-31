CREATE TABLE "admin_mutation_results" (
	"request_id" text PRIMARY KEY NOT NULL,
	"action" text NOT NULL,
	"response" jsonb NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
DROP INDEX "admin_audit_events_request_id_unique";--> statement-breakpoint
CREATE INDEX "admin_audit_events_request_id_idx" ON "admin_audit_events" USING btree ("request_id");
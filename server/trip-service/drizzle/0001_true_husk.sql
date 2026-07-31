ALTER TABLE "rides" ADD COLUMN "creation_request_id" text;--> statement-breakpoint
ALTER TABLE "rides" ADD COLUMN "creation_request_hash" text;--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "rides_creation_request_id_unique" ON "rides" ("creation_request_id");
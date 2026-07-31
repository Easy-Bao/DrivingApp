ALTER TABLE "admin_mutation_results" ADD COLUMN "target_type" text;--> statement-breakpoint
ALTER TABLE "admin_mutation_results" ADD COLUMN "target_id" text;--> statement-breakpoint
ALTER TABLE "admin_mutation_results" ADD COLUMN "request_hash" text;--> statement-breakpoint
UPDATE "admin_mutation_results"
SET
	"target_type" = 'legacy',
	"request_hash" = 'legacy:' || "request_id";--> statement-breakpoint
ALTER TABLE "admin_mutation_results" ALTER COLUMN "target_type" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "admin_mutation_results" ALTER COLUMN "request_hash" SET NOT NULL;

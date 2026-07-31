CREATE TABLE IF NOT EXISTS "drivers" (
  "id" text PRIMARY KEY NOT NULL,
  "name" text NOT NULL,
  "email" text NOT NULL UNIQUE,
  "phone" text NOT NULL,
  "vehicle_type" text NOT NULL,
  "plate_number" text NOT NULL,
  "password_hash" text NOT NULL,
  "rating" double precision DEFAULT 5 NOT NULL,
  "is_online" boolean DEFAULT false NOT NULL,
  "lat" double precision DEFAULT 7.828282 NOT NULL,
  "lng" double precision DEFAULT 123.434343 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE "drivers"
  ADD COLUMN IF NOT EXISTS "approval_status" text DEFAULT 'pending' NOT NULL,
  ADD COLUMN IF NOT EXISTS "approval_reason" text,
  ADD COLUMN IF NOT EXISTS "approval_reviewed_by" text,
  ADD COLUMN IF NOT EXISTS "approval_reviewed_at" timestamp with time zone;

DO $$ BEGIN
  ALTER TABLE "drivers"
    ADD CONSTRAINT "drivers_approval_status_check"
    CHECK ("approval_status" IN ('pending', 'approved', 'rejected'));
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS "driver_document_requirements" (
  "id" text PRIMARY KEY NOT NULL,
  "name" text NOT NULL,
  "normalized_name" text NOT NULL,
  "is_active" boolean DEFAULT true NOT NULL,
  "created_by" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "driver_document_requirements_normalized_name_unique"
  ON "driver_document_requirements" ("normalized_name");

CREATE TABLE IF NOT EXISTS "driver_document_checks" (
  "id" text PRIMARY KEY NOT NULL,
  "driver_id" text NOT NULL REFERENCES "drivers"("id") ON DELETE CASCADE,
  "requirement_id" text NOT NULL REFERENCES "driver_document_requirements"("id") ON DELETE CASCADE,
  "status" text DEFAULT 'pending' NOT NULL
    CHECK ("status" IN ('pending', 'verified', 'rejected', 'expired')),
  "expires_at" timestamp with time zone,
  "notes" text,
  "reviewed_by" text,
  "reviewed_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "driver_document_checks_driver_requirement_unique"
  ON "driver_document_checks" ("driver_id", "requirement_id");
CREATE INDEX IF NOT EXISTS "driver_document_checks_driver_idx"
  ON "driver_document_checks" ("driver_id");

CREATE TABLE IF NOT EXISTS "driver_account_restrictions" (
  "id" text PRIMARY KEY NOT NULL,
  "driver_id" text NOT NULL REFERENCES "drivers"("id") ON DELETE CASCADE,
  "status" text DEFAULT 'active' NOT NULL
    CHECK ("status" IN ('active', 'lifted')),
  "reason" text NOT NULL,
  "expires_at" timestamp with time zone,
  "created_by" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "lifted_by" text,
  "lifted_reason" text,
  "lifted_at" timestamp with time zone
);

CREATE UNIQUE INDEX IF NOT EXISTS "driver_account_restrictions_active_unique"
  ON "driver_account_restrictions" ("driver_id")
  WHERE "status" = 'active';

CREATE TABLE IF NOT EXISTS "driver_credit_wallets" (
  "driver_id" text PRIMARY KEY NOT NULL REFERENCES "drivers"("id") ON DELETE CASCADE,
  "balance_centavos" integer DEFAULT 0 NOT NULL
    CHECK ("balance_centavos" >= 0),
  "reserved_centavos" integer DEFAULT 0 NOT NULL
    CHECK ("reserved_centavos" >= 0),
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "driver_credit_wallets_reservation_covered"
    CHECK ("balance_centavos" >= "reserved_centavos")
);

CREATE TABLE IF NOT EXISTS "driver_topup_channels" (
  "id" text PRIMARY KEY NOT NULL,
  "name" text NOT NULL,
  "account_name" text NOT NULL,
  "account_reference" text NOT NULL,
  "instructions" text,
  "is_active" boolean DEFAULT true NOT NULL,
  "created_by" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "driver_topup_requests" (
  "id" text PRIMARY KEY NOT NULL,
  "driver_id" text NOT NULL REFERENCES "drivers"("id") ON DELETE CASCADE,
  "channel_id" text NOT NULL REFERENCES "driver_topup_channels"("id"),
  "amount_centavos" integer NOT NULL CHECK ("amount_centavos" > 0),
  "sender_name" text NOT NULL,
  "transaction_reference" text NOT NULL,
  "normalized_transaction_reference" text NOT NULL,
  "status" text DEFAULT 'pending' NOT NULL
    CHECK ("status" IN ('pending', 'approved', 'rejected')),
  "submitted_at" timestamp with time zone DEFAULT now() NOT NULL,
  "reviewed_by" text,
  "reviewed_at" timestamp with time zone,
  "review_reason" text
);

CREATE UNIQUE INDEX IF NOT EXISTS "driver_topup_requests_channel_reference_unique"
  ON "driver_topup_requests" ("channel_id", "normalized_transaction_reference");
CREATE INDEX IF NOT EXISTS "driver_topup_requests_driver_idx"
  ON "driver_topup_requests" ("driver_id", "submitted_at" DESC);
CREATE INDEX IF NOT EXISTS "driver_topup_requests_status_idx"
  ON "driver_topup_requests" ("status", "submitted_at");

CREATE TABLE IF NOT EXISTS "driver_credit_reservations" (
  "id" text PRIMARY KEY NOT NULL,
  "driver_id" text NOT NULL REFERENCES "drivers"("id") ON DELETE CASCADE,
  "ride_id" text NOT NULL,
  "fare_centavos" integer NOT NULL CHECK ("fare_centavos" >= 0),
  "commission_basis_points" integer NOT NULL
    CHECK ("commission_basis_points" BETWEEN 0 AND 10000),
  "commission_centavos" integer NOT NULL CHECK ("commission_centavos" >= 0),
  "status" text DEFAULT 'reserved' NOT NULL
    CHECK ("status" IN ('reserved', 'settled', 'released', 'disputed')),
  "dispute_reason" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "driver_credit_reservations_ride_unique"
  ON "driver_credit_reservations" ("ride_id");
CREATE INDEX IF NOT EXISTS "driver_credit_reservations_driver_idx"
  ON "driver_credit_reservations" ("driver_id", "created_at" DESC);

CREATE TABLE IF NOT EXISTS "driver_credit_ledger" (
  "id" text PRIMARY KEY NOT NULL,
  "driver_id" text NOT NULL REFERENCES "drivers"("id") ON DELETE CASCADE,
  "type" text NOT NULL
    CHECK ("type" IN ('topup', 'adjustment', 'refund', 'reserve', 'settle', 'release', 'dispute')),
  "balance_delta_centavos" integer NOT NULL,
  "reserved_delta_centavos" integer NOT NULL,
  "balance_after_centavos" integer NOT NULL,
  "reserved_after_centavos" integer NOT NULL,
  "ride_id" text,
  "topup_request_id" text REFERENCES "driver_topup_requests"("id"),
  "actor_id" text NOT NULL,
  "reason" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS "driver_credit_ledger_driver_idx"
  ON "driver_credit_ledger" ("driver_id", "created_at" DESC);

CREATE OR REPLACE FUNCTION "prevent_driver_credit_ledger_mutation"()
RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'driver_credit_ledger is append-only';
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'driver_credit_ledger_immutable'
  ) THEN
    CREATE TRIGGER "driver_credit_ledger_immutable"
      BEFORE UPDATE OR DELETE ON "driver_credit_ledger"
      FOR EACH ROW
      EXECUTE FUNCTION "prevent_driver_credit_ledger_mutation"();
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS "driver_idempotency_records" (
  "operation" text NOT NULL,
  "idempotency_key" text NOT NULL,
  "request_hash" text NOT NULL,
  "response_json" jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "driver_idempotency_records_primary_key"
    PRIMARY KEY ("operation", "idempotency_key")
);

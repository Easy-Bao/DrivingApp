-- Migration 0002 retained legacy rows whose original commission rate is unknown.
-- Every row with a rate snapshot must have an exact integer-centavo split.
ALTER TABLE "fare_transactions"
  ADD CONSTRAINT "fare_transactions_snapshot_integrity"
  CHECK (
    "commission_rate_basis_points" IS NULL
    OR (
      "total_fare_centavos" IS NOT NULL
      AND "driver_earnings_centavos" IS NOT NULL
      AND "platform_fee_centavos" IS NOT NULL
      AND "total_fare_centavos" >= 0
      AND "driver_earnings_centavos" >= 0
      AND "platform_fee_centavos" >= 0
      AND "commission_rate_basis_points" BETWEEN 0 AND 10000
      AND "total_fare_centavos"::bigint =
        "driver_earnings_centavos"::bigint + "platform_fee_centavos"::bigint
      AND "platform_fee_centavos" = (
        (
          "total_fare_centavos"::bigint * "commission_rate_basis_points"
          + 5000
        ) / 10000
      )::integer
    )
  );
--> statement-breakpoint
ALTER TABLE "fare_transactions"
  ADD CONSTRAINT "fare_transactions_assignment_source_allowed"
  CHECK ("assignment_source" IN ('driver_offer', 'admin'));
--> statement-breakpoint
ALTER TABLE "fare_transactions"
  ADD CONSTRAINT "fare_transactions_payment_status_allowed"
  CHECK (
    "payment_status" IN (
      'cash_pending',
      'cash_received',
      'cash_disputed',
      'canceled'
    )
  );
--> statement-breakpoint
CREATE OR REPLACE FUNCTION "prevent_fare_transaction_snapshot_mutation"()
RETURNS trigger AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'fare transaction snapshot is immutable' USING ERRCODE = '23514';
  END IF;

  IF ROW(
    NEW."id",
    NEW."ride_id",
    NEW."service_type",
    NEW."distance_km",
    NEW."duration_minutes",
    NEW."base_fare",
    NEW."distance_charge",
    NEW."time_charge",
    NEW."surge_charge",
    NEW."total_fare",
    NEW."driver_earnings",
    NEW."platform_fee",
    NEW."driver_id",
    NEW."total_fare_centavos",
    NEW."driver_earnings_centavos",
    NEW."platform_fee_centavos",
    NEW."commission_rate_basis_points",
    NEW."assignment_source",
    NEW."created_at"
  ) IS DISTINCT FROM ROW(
    OLD."id",
    OLD."ride_id",
    OLD."service_type",
    OLD."distance_km",
    OLD."duration_minutes",
    OLD."base_fare",
    OLD."distance_charge",
    OLD."time_charge",
    OLD."surge_charge",
    OLD."total_fare",
    OLD."driver_earnings",
    OLD."platform_fee",
    OLD."driver_id",
    OLD."total_fare_centavos",
    OLD."driver_earnings_centavos",
    OLD."platform_fee_centavos",
    OLD."commission_rate_basis_points",
    OLD."assignment_source",
    OLD."created_at"
  ) THEN
    RAISE EXCEPTION 'fare transaction snapshot is immutable' USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--> statement-breakpoint
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'fare_transactions_snapshot_immutable'
      AND tgrelid = 'fare_transactions'::regclass
  ) THEN
    CREATE TRIGGER "fare_transactions_snapshot_immutable"
      BEFORE UPDATE OR DELETE ON "fare_transactions"
      FOR EACH ROW
      EXECUTE FUNCTION "prevent_fare_transaction_snapshot_mutation"();
  END IF;
END $$;

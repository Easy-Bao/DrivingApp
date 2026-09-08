-- This baseline reconciles the schema created by the former Ent runner with
-- the native query boundary. It is intentionally idempotent so an existing
-- deployment can adopt the new migration ledger without rewriting data.

CREATE TABLE IF NOT EXISTS users (
    id serial PRIMARY KEY,
    name text DEFAULT '',
    phone text NOT NULL UNIQUE,
    email text NOT NULL UNIQUE,
    password_hash text NOT NULL,
    role text NOT NULL,
    is_verified boolean NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS driver_profiles (
    id serial PRIMARY KEY,
    user_id integer NOT NULL UNIQUE,
    name text NOT NULL,
    vehicle_type text NOT NULL,
    plate_number text NOT NULL,
    rating double precision NOT NULL DEFAULT 0,
    is_online boolean NOT NULL DEFAULT false,
    wallet_balance_centavos bigint NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS passenger_profiles (
    id serial PRIMARY KEY,
    user_id integer NOT NULL UNIQUE,
    name text NOT NULL,
    address text,
    gender text NOT NULL DEFAULT 'Prefer not to say',
    avatar_storage_key text,
    avatar_content_type text,
    preferred_ride_type text
);

CREATE TABLE IF NOT EXISTS rides (
    id serial PRIMARY KEY,
    passenger_id integer NOT NULL,
    driver_id integer,
    status text NOT NULL DEFAULT 'requested',
    fare_centavos bigint NOT NULL,
    ride_type text NOT NULL DEFAULT 'Solo Ride',
    pickup_latitude double precision,
    pickup_longitude double precision,
    pickup_name text,
    dropoff_latitude double precision,
    dropoff_longitude double precision,
    dropoff_name text,
    distance_km double precision,
    duration_minutes double precision,
    driver_name text,
    vehicle_type text,
    plate_number text,
    driver_rating double precision,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at timestamptz,
    payment_status text NOT NULL DEFAULT 'unpaid',
    cash_received_at timestamptz,
    commission_bps bigint,
    commission_centavos bigint NOT NULL DEFAULT 0,
    driver_payout_centavos bigint NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS bid_sessions (
    id serial PRIMARY KEY,
    passenger_id integer NOT NULL,
    ride_type text NOT NULL DEFAULT 'Solo Ride',
    pickup_latitude double precision NOT NULL,
    pickup_longitude double precision NOT NULL,
    pickup_name text NOT NULL,
    dropoff_latitude double precision NOT NULL,
    dropoff_longitude double precision NOT NULL,
    dropoff_name text NOT NULL,
    passenger_note text,
    distance_km double precision NOT NULL,
    duration_minutes double precision NOT NULL,
    offered_fare_centavos bigint NOT NULL,
    status text NOT NULL DEFAULT 'open',
    target_driver_id integer,
    accepted_driver_id integer,
    expires_at timestamptz NOT NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bid_offers (
    id serial PRIMARY KEY,
    session_id integer NOT NULL,
    driver_id integer NOT NULL,
    driver_name text,
    plate_number text,
    vehicle_type text,
    proposed_fare_centavos bigint NOT NULL,
    status text NOT NULL DEFAULT 'pending',
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bids (
    id serial PRIMARY KEY,
    ride_id integer NOT NULL,
    driver_id integer NOT NULL,
    offered_fare_centavos bigint NOT NULL,
    status text NOT NULL DEFAULT 'pending'
);

CREATE TABLE IF NOT EXISTS reviews (
    id serial PRIMARY KEY,
    ride_id integer,
    driver_id integer NOT NULL,
    passenger_id integer NOT NULL,
    passenger_name text,
    rating double precision NOT NULL,
    comment text,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS passenger_reviews (
    id serial PRIMARY KEY,
    ride_id integer NOT NULL,
    driver_id integer NOT NULL,
    passenger_id integer NOT NULL,
    rating double precision NOT NULL,
    comment text,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS notifications (
    id serial PRIMARY KEY,
    user_id integer NOT NULL,
    type text NOT NULL DEFAULT 'general',
    title text NOT NULL,
    body text NOT NULL,
    is_read boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS driver_documents (
    id serial PRIMARY KEY,
    driver_id integer NOT NULL,
    document_type varchar(64) NOT NULL,
    storage_key varchar(160) NOT NULL,
    status varchar(16) NOT NULL DEFAULT 'pending',
    content_type varchar(64) NOT NULL DEFAULT 'application/octet-stream',
    size_bytes bigint NOT NULL DEFAULT 0,
    checksum_sha256 varchar(64) NOT NULL DEFAULT '',
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reviewed_at timestamptz,
    reviewed_by integer
);

CREATE TABLE IF NOT EXISTS driver_wallet_accounts (
    id serial PRIMARY KEY,
    driver_id integer NOT NULL,
    balance_centavos bigint NOT NULL DEFAULT 0,
    version bigint NOT NULL DEFAULT 0,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ride_settlements (
    id serial PRIMARY KEY,
    ride_id integer NOT NULL,
    gross_fare_centavos bigint NOT NULL,
    commission_bps bigint,
    commission_centavos bigint NOT NULL DEFAULT 0,
    driver_payout_centavos bigint NOT NULL DEFAULT 0,
    payment_status text NOT NULL DEFAULT 'unpaid',
    cash_received_at timestamptz,
    settled_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS wallet_ledgers (
    id serial PRIMARY KEY,
    driver_id integer NOT NULL,
    ride_id integer NOT NULL,
    amount_centavos bigint NOT NULL,
    commission_centavos bigint NOT NULL,
    kind text NOT NULL DEFAULT 'cash_trip',
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS refresh_sessions (
    id serial PRIMARY KEY,
    user_id integer NOT NULL,
    token_hash varchar(64) NOT NULL UNIQUE,
    expires_at timestamptz NOT NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_used_at timestamptz,
    revoked_at timestamptz
);

CREATE TABLE IF NOT EXISTS private_objects (
    id serial PRIMARY KEY,
    storage_key varchar(80) NOT NULL UNIQUE,
    content bytea NOT NULL,
    content_type varchar(128) NOT NULL,
    size_bytes bigint NOT NULL,
    checksum_sha256 varchar(64) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS audit_events (
    id serial PRIMARY KEY,
    actor_id integer NOT NULL,
    action text NOT NULL,
    target_type text NOT NULL,
    target_id text,
    outcome text NOT NULL,
    request_id text NOT NULL UNIQUE,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- These columns were introduced by later Ent schema revisions. Keep the
-- adoption safe for databases that have only the earlier table shape.
ALTER TABLE driver_documents
    ADD COLUMN IF NOT EXISTS content_type varchar(64) NOT NULL DEFAULT 'application/octet-stream';
ALTER TABLE driver_documents
    ADD COLUMN IF NOT EXISTS size_bytes bigint NOT NULL DEFAULT 0;
ALTER TABLE driver_documents
    ADD COLUMN IF NOT EXISTS checksum_sha256 varchar(64) NOT NULL DEFAULT '';
ALTER TABLE driver_documents
    ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE driver_documents
    ADD COLUMN IF NOT EXISTS reviewed_at timestamptz;

DO $migration$
DECLARE
    user_id_type text;
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = current_schema()
          AND table_name = 'driver_documents'
          AND column_name = 'reviewed_by'
    ) THEN
        SELECT format_type(attribute.atttypid, attribute.atttypmod)
        INTO user_id_type
        FROM pg_attribute AS attribute
        JOIN pg_class AS relation ON relation.oid = attribute.attrelid
        JOIN pg_namespace AS namespace ON namespace.oid = relation.relnamespace
        WHERE namespace.nspname = current_schema()
          AND relation.relname = 'users'
          AND attribute.attname = 'id'
          AND attribute.attnum > 0
          AND NOT attribute.attisdropped;
        IF user_id_type IS NULL THEN
            RAISE EXCEPTION 'users.id type is unavailable';
        END IF;
        EXECUTE format('ALTER TABLE driver_documents ADD COLUMN reviewed_by %s', user_id_type);
    END IF;
END
$migration$;

ALTER TABLE passenger_profiles
    ADD COLUMN IF NOT EXISTS gender varchar(32) NOT NULL DEFAULT 'Prefer not to say';
ALTER TABLE passenger_profiles
    ADD COLUMN IF NOT EXISTS avatar_storage_key varchar(160);
ALTER TABLE passenger_profiles
    ADD COLUMN IF NOT EXISTS avatar_content_type varchar(64);

-- Keep identifiers compatible with the native generated query models. The
-- previous runner accepted integer and bigint identifiers; incompatible
-- types still fail with an actionable migration error.
DO $migration$
DECLARE
    relation_name text;
    id_type text;
BEGIN
    FOREACH relation_name IN ARRAY ARRAY[
        'users',
        'rides',
        'bid_sessions',
        'reviews',
        'notifications'
    ] LOOP
        SELECT data_type
        INTO id_type
        FROM information_schema.columns
        WHERE table_schema = current_schema()
          AND table_name = relation_name
          AND column_name = 'id';
        IF id_type IS NOT NULL AND id_type NOT IN ('integer', 'bigint') THEN
            RAISE EXCEPTION
                'table % uses incompatible id type %; migrate it explicitly before applying the native schema',
                relation_name,
                id_type;
        END IF;
    END LOOP;
END
$migration$;

CREATE UNIQUE INDEX IF NOT EXISTS passengerprofile_user_id
    ON passenger_profiles (user_id);
CREATE UNIQUE INDEX IF NOT EXISTS driverprofile_user_id
    ON driver_profiles (user_id);
CREATE UNIQUE INDEX IF NOT EXISTS driverwalletaccount_driver_id
    ON driver_wallet_accounts (driver_id);
CREATE UNIQUE INDEX IF NOT EXISTS ridesettlement_ride_id
    ON ride_settlements (ride_id);
CREATE INDEX IF NOT EXISTS ride_passenger_id_created_at
    ON rides (passenger_id, created_at);
CREATE INDEX IF NOT EXISTS ride_driver_id_created_at
    ON rides (driver_id, created_at);
CREATE UNIQUE INDEX IF NOT EXISTS ride_passenger_id
    ON rides (passenger_id)
    WHERE status IN ('requested', 'assigned', 'accepted', 'arrived', 'in_transit');
CREATE INDEX IF NOT EXISTS ride_passenger_id_status_completed_at
    ON rides (passenger_id, status, completed_at);
CREATE INDEX IF NOT EXISTS ride_driver_id_status_completed_at
    ON rides (driver_id, status, completed_at);
CREATE INDEX IF NOT EXISTS bidsession_expires_at_created_at
    ON bid_sessions (expires_at, created_at);
CREATE INDEX IF NOT EXISTS bidsession_target_driver_id_created_at
    ON bid_sessions (target_driver_id, created_at);
CREATE UNIQUE INDEX IF NOT EXISTS bidsession_passenger_id
    ON bid_sessions (passenger_id)
    WHERE status = 'open';
CREATE INDEX IF NOT EXISTS bidoffer_session_id_created_at
    ON bid_offers (session_id, created_at);
CREATE UNIQUE INDEX IF NOT EXISTS bidoffer_session_id_driver_id
    ON bid_offers (session_id, driver_id)
    WHERE status = 'pending';
CREATE UNIQUE INDEX IF NOT EXISTS bid_ride_id_driver_id
    ON bids (ride_id, driver_id)
    WHERE status = 'pending';
CREATE UNIQUE INDEX IF NOT EXISTS review_ride_id
    ON reviews (ride_id)
    WHERE ride_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS review_driver_id_created_at
    ON reviews (driver_id, created_at);
CREATE UNIQUE INDEX IF NOT EXISTS passengerreview_ride_id
    ON passenger_reviews (ride_id);
CREATE INDEX IF NOT EXISTS passengerreview_passenger_id_created_at
    ON passenger_reviews (passenger_id, created_at);
CREATE INDEX IF NOT EXISTS notification_user_id_created_at
    ON notifications (user_id, created_at);
CREATE INDEX IF NOT EXISTS driver_document_driver_type_created_at
    ON driver_documents (driver_id, document_type, created_at);
CREATE INDEX IF NOT EXISTS driver_document_status_created_at
    ON driver_documents (status, created_at);
CREATE INDEX IF NOT EXISTS wallet_ledger_driver_created_idx
    ON wallet_ledgers (driver_id, created_at);
CREATE INDEX IF NOT EXISTS auditevent_actor_id_created_at
    ON audit_events (actor_id, created_at);
CREATE INDEX IF NOT EXISTS refreshsession_user_id_expires_at
    ON refresh_sessions (user_id, expires_at);
CREATE INDEX IF NOT EXISTS refreshsession_expires_at_revoked_at
    ON refresh_sessions (expires_at, revoked_at);
DROP INDEX IF EXISTS ride_driver_id_status;
DROP INDEX IF EXISTS driverdocument_driver_id_document_type;

UPDATE bid_sessions
SET status = 'expired'
WHERE status = 'open'
  AND expires_at <= CURRENT_TIMESTAMP;

INSERT INTO driver_wallet_accounts (
    driver_id,
    balance_centavos,
    version,
    updated_at
)
SELECT
    user_id,
    wallet_balance_centavos,
    0,
    CURRENT_TIMESTAMP
FROM driver_profiles
ON CONFLICT (driver_id) DO NOTHING;

INSERT INTO ride_settlements (
    ride_id,
    gross_fare_centavos,
    commission_bps,
    commission_centavos,
    driver_payout_centavos,
    payment_status,
    cash_received_at,
    settled_at,
    created_at,
    updated_at
)
SELECT
    id,
    fare_centavos,
    commission_bps,
    commission_centavos,
    driver_payout_centavos,
    payment_status,
    cash_received_at,
    cash_received_at,
    created_at,
    CURRENT_TIMESTAMP
FROM rides
ON CONFLICT (ride_id) DO NOTHING;

UPDATE driver_documents
SET status = 'pending'
WHERE status NOT IN ('pending', 'approved', 'rejected');
UPDATE driver_documents
SET document_type = 'legacy_document'
WHERE document_type !~ '^[a-z][a-z0-9_]{0,63}$';
UPDATE driver_documents
SET content_type = 'application/octet-stream'
WHERE content_type NOT IN (
    'application/octet-stream',
    'application/pdf',
    'image/jpeg',
    'image/png'
);
UPDATE driver_documents
SET size_bytes = 0,
    checksum_sha256 = ''
WHERE size_bytes < 0
   OR (size_bytes = 0 AND checksum_sha256 <> '')
   OR (size_bytes > 0 AND checksum_sha256 !~ '^[a-f0-9]{64}$');
UPDATE driver_documents
SET reviewed_at = created_at
WHERE status IN ('approved', 'rejected')
  AND reviewed_at IS NULL;
UPDATE driver_documents
SET reviewed_at = NULL,
    reviewed_by = NULL
WHERE status = 'pending';

ALTER TABLE driver_documents DROP CONSTRAINT IF EXISTS driver_documents_status_check;
ALTER TABLE driver_documents ADD CONSTRAINT driver_documents_status_check
    CHECK (status IN ('pending', 'approved', 'rejected'));
ALTER TABLE driver_documents DROP CONSTRAINT IF EXISTS driver_documents_type_check;
ALTER TABLE driver_documents ADD CONSTRAINT driver_documents_type_check
    CHECK (document_type ~ '^[a-z][a-z0-9_]{0,63}$');
ALTER TABLE driver_documents DROP CONSTRAINT IF EXISTS driver_documents_content_type_check;
ALTER TABLE driver_documents ADD CONSTRAINT driver_documents_content_type_check
    CHECK (content_type IN ('application/octet-stream', 'application/pdf', 'image/jpeg', 'image/png'));
ALTER TABLE driver_documents DROP CONSTRAINT IF EXISTS driver_documents_integrity_check;
ALTER TABLE driver_documents ADD CONSTRAINT driver_documents_integrity_check
    CHECK (
        (size_bytes = 0 AND checksum_sha256 = '')
        OR (size_bytes > 0 AND checksum_sha256 ~ '^[a-f0-9]{64}$')
    );
ALTER TABLE driver_documents DROP CONSTRAINT IF EXISTS driver_documents_review_check;
ALTER TABLE driver_documents ADD CONSTRAINT driver_documents_review_check
    CHECK (
        (status = 'pending' AND reviewed_at IS NULL AND reviewed_by IS NULL)
        OR (status IN ('approved', 'rejected') AND reviewed_at IS NOT NULL)
    );

UPDATE passenger_profiles
SET gender = 'Prefer not to say'
WHERE gender IS NULL
   OR gender NOT IN ('Female', 'Male', 'Non-binary', 'Prefer not to say');
ALTER TABLE passenger_profiles ALTER COLUMN gender SET DEFAULT 'Prefer not to say';
ALTER TABLE passenger_profiles ALTER COLUMN gender SET NOT NULL;
ALTER TABLE passenger_profiles DROP CONSTRAINT IF EXISTS passenger_profiles_gender_check;
ALTER TABLE passenger_profiles ADD CONSTRAINT passenger_profiles_gender_check
    CHECK (gender IN ('Female', 'Male', 'Non-binary', 'Prefer not to say'));
ALTER TABLE passenger_profiles DROP CONSTRAINT IF EXISTS passenger_profiles_avatar_content_type_check;
ALTER TABLE passenger_profiles ADD CONSTRAINT passenger_profiles_avatar_content_type_check
    CHECK (avatar_content_type IS NULL OR avatar_content_type IN ('image/jpeg', 'image/png'));

UPDATE rides
SET status = 'cancelled'
WHERE status = 'canceled';
ALTER TABLE rides DROP CONSTRAINT IF EXISTS rides_status_check;
ALTER TABLE rides ADD CONSTRAINT rides_status_check
    CHECK (status IN ('requested', 'assigned', 'accepted', 'arrived', 'in_transit', 'completed', 'cancelled'))
    NOT VALID;
ALTER TABLE rides VALIDATE CONSTRAINT rides_status_check;
ALTER TABLE rides DROP CONSTRAINT IF EXISTS rides_driver_assignment_check;
ALTER TABLE rides ADD CONSTRAINT rides_driver_assignment_check
    CHECK (status IN ('requested', 'cancelled') OR (driver_id IS NOT NULL AND driver_id > 0))
    NOT VALID;
ALTER TABLE rides VALIDATE CONSTRAINT rides_driver_assignment_check;
ALTER TABLE rides DROP CONSTRAINT IF EXISTS rides_payment_status_check;
ALTER TABLE rides ADD CONSTRAINT rides_payment_status_check
    CHECK (payment_status IN ('unpaid', 'paid'))
    NOT VALID;
ALTER TABLE rides VALIDATE CONSTRAINT rides_payment_status_check;
UPDATE bid_sessions
SET status = 'cancelled'
WHERE status = 'canceled';
ALTER TABLE bid_sessions DROP CONSTRAINT IF EXISTS bid_sessions_status_check;
ALTER TABLE bid_sessions ADD CONSTRAINT bid_sessions_status_check
    CHECK (status IN ('open', 'accepted', 'cancelled', 'expired'))
    NOT VALID;
ALTER TABLE bid_sessions VALIDATE CONSTRAINT bid_sessions_status_check;
ALTER TABLE bid_offers DROP CONSTRAINT IF EXISTS bid_offers_status_check;
ALTER TABLE bid_offers ADD CONSTRAINT bid_offers_status_check
    CHECK (status IN ('pending', 'accepted', 'rejected'))
    NOT VALID;
ALTER TABLE bid_offers VALIDATE CONSTRAINT bid_offers_status_check;
ALTER TABLE bids DROP CONSTRAINT IF EXISTS bids_status_check;
ALTER TABLE bids ADD CONSTRAINT bids_status_check
    CHECK (status IN ('pending', 'accepted', 'rejected'))
    NOT VALID;
ALTER TABLE bids VALIDATE CONSTRAINT bids_status_check;
ALTER TABLE ride_settlements DROP CONSTRAINT IF EXISTS ride_settlements_payment_status_check;
ALTER TABLE ride_settlements ADD CONSTRAINT ride_settlements_payment_status_check
    CHECK (payment_status IN ('unpaid', 'paid'))
    NOT VALID;
ALTER TABLE ride_settlements VALIDATE CONSTRAINT ride_settlements_payment_status_check;

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'passenger_profiles_user_fk') THEN
        ALTER TABLE passenger_profiles ADD CONSTRAINT passenger_profiles_user_fk
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'driver_profiles_user_fk') THEN
        ALTER TABLE driver_profiles ADD CONSTRAINT driver_profiles_user_fk
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'driver_wallet_accounts_driver_fk') THEN
        ALTER TABLE driver_wallet_accounts ADD CONSTRAINT driver_wallet_accounts_driver_fk
            FOREIGN KEY (driver_id) REFERENCES users (id) ON DELETE RESTRICT NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'rides_passenger_fk') THEN
        ALTER TABLE rides ADD CONSTRAINT rides_passenger_fk
            FOREIGN KEY (passenger_id) REFERENCES users (id) ON DELETE RESTRICT NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'rides_driver_fk') THEN
        ALTER TABLE rides ADD CONSTRAINT rides_driver_fk
            FOREIGN KEY (driver_id) REFERENCES users (id) ON DELETE RESTRICT NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ride_settlements_ride_fk') THEN
        ALTER TABLE ride_settlements ADD CONSTRAINT ride_settlements_ride_fk
            FOREIGN KEY (ride_id) REFERENCES rides (id) ON DELETE RESTRICT NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'bid_sessions_passenger_fk') THEN
        ALTER TABLE bid_sessions ADD CONSTRAINT bid_sessions_passenger_fk
            FOREIGN KEY (passenger_id) REFERENCES users (id) ON DELETE RESTRICT NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'bid_sessions_target_driver_fk') THEN
        ALTER TABLE bid_sessions ADD CONSTRAINT bid_sessions_target_driver_fk
            FOREIGN KEY (target_driver_id) REFERENCES users (id) ON DELETE RESTRICT NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'bid_sessions_accepted_driver_fk') THEN
        ALTER TABLE bid_sessions ADD CONSTRAINT bid_sessions_accepted_driver_fk
            FOREIGN KEY (accepted_driver_id) REFERENCES users (id) ON DELETE RESTRICT NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'bid_offers_session_fk') THEN
        ALTER TABLE bid_offers ADD CONSTRAINT bid_offers_session_fk
            FOREIGN KEY (session_id) REFERENCES bid_sessions (id) ON DELETE CASCADE NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'bid_offers_driver_fk') THEN
        ALTER TABLE bid_offers ADD CONSTRAINT bid_offers_driver_fk
            FOREIGN KEY (driver_id) REFERENCES users (id) ON DELETE RESTRICT NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'bids_ride_fk') THEN
        ALTER TABLE bids ADD CONSTRAINT bids_ride_fk
            FOREIGN KEY (ride_id) REFERENCES rides (id) ON DELETE CASCADE NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'bids_driver_fk') THEN
        ALTER TABLE bids ADD CONSTRAINT bids_driver_fk
            FOREIGN KEY (driver_id) REFERENCES users (id) ON DELETE RESTRICT NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'reviews_ride_fk') THEN
        ALTER TABLE reviews ADD CONSTRAINT reviews_ride_fk
            FOREIGN KEY (ride_id) REFERENCES rides (id) ON DELETE CASCADE NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'reviews_driver_fk') THEN
        ALTER TABLE reviews ADD CONSTRAINT reviews_driver_fk
            FOREIGN KEY (driver_id) REFERENCES users (id) ON DELETE RESTRICT NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'reviews_passenger_fk') THEN
        ALTER TABLE reviews ADD CONSTRAINT reviews_passenger_fk
            FOREIGN KEY (passenger_id) REFERENCES users (id) ON DELETE RESTRICT NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'passenger_reviews_ride_fk') THEN
        ALTER TABLE passenger_reviews ADD CONSTRAINT passenger_reviews_ride_fk
            FOREIGN KEY (ride_id) REFERENCES rides (id) ON DELETE CASCADE NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'passenger_reviews_driver_fk') THEN
        ALTER TABLE passenger_reviews ADD CONSTRAINT passenger_reviews_driver_fk
            FOREIGN KEY (driver_id) REFERENCES users (id) ON DELETE RESTRICT NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'passenger_reviews_passenger_fk') THEN
        ALTER TABLE passenger_reviews ADD CONSTRAINT passenger_reviews_passenger_fk
            FOREIGN KEY (passenger_id) REFERENCES users (id) ON DELETE RESTRICT NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'notifications_user_fk') THEN
        ALTER TABLE notifications ADD CONSTRAINT notifications_user_fk
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'driver_documents_driver_fk') THEN
        ALTER TABLE driver_documents ADD CONSTRAINT driver_documents_driver_fk
            FOREIGN KEY (driver_id) REFERENCES users (id) ON DELETE RESTRICT NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'driver_documents_reviewer_fk') THEN
        ALTER TABLE driver_documents ADD CONSTRAINT driver_documents_reviewer_fk
            FOREIGN KEY (reviewed_by) REFERENCES users (id) ON DELETE SET NULL NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'refresh_sessions_user_fk') THEN
        ALTER TABLE refresh_sessions ADD CONSTRAINT refresh_sessions_user_fk
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'wallet_ledgers_driver_fk') THEN
        ALTER TABLE wallet_ledgers ADD CONSTRAINT wallet_ledgers_driver_fk
            FOREIGN KEY (driver_id) REFERENCES users (id) ON DELETE RESTRICT NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'wallet_ledgers_ride_fk') THEN
        ALTER TABLE wallet_ledgers ADD CONSTRAINT wallet_ledgers_ride_fk
            FOREIGN KEY (ride_id) REFERENCES rides (id) ON DELETE RESTRICT NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'audit_events_actor_fk') THEN
        ALTER TABLE audit_events ADD CONSTRAINT audit_events_actor_fk
            FOREIGN KEY (actor_id) REFERENCES users (id) ON DELETE RESTRICT NOT VALID;
    END IF;
END
$migration$;

ALTER TABLE passenger_profiles VALIDATE CONSTRAINT passenger_profiles_user_fk;
ALTER TABLE driver_profiles VALIDATE CONSTRAINT driver_profiles_user_fk;
ALTER TABLE driver_wallet_accounts VALIDATE CONSTRAINT driver_wallet_accounts_driver_fk;
ALTER TABLE rides VALIDATE CONSTRAINT rides_passenger_fk;
ALTER TABLE rides VALIDATE CONSTRAINT rides_driver_fk;
ALTER TABLE ride_settlements VALIDATE CONSTRAINT ride_settlements_ride_fk;
ALTER TABLE bid_sessions VALIDATE CONSTRAINT bid_sessions_passenger_fk;
ALTER TABLE bid_sessions VALIDATE CONSTRAINT bid_sessions_target_driver_fk;
ALTER TABLE bid_sessions VALIDATE CONSTRAINT bid_sessions_accepted_driver_fk;
ALTER TABLE bid_offers VALIDATE CONSTRAINT bid_offers_session_fk;
ALTER TABLE bid_offers VALIDATE CONSTRAINT bid_offers_driver_fk;
ALTER TABLE bids VALIDATE CONSTRAINT bids_ride_fk;
ALTER TABLE bids VALIDATE CONSTRAINT bids_driver_fk;
ALTER TABLE reviews VALIDATE CONSTRAINT reviews_ride_fk;
ALTER TABLE reviews VALIDATE CONSTRAINT reviews_driver_fk;
ALTER TABLE reviews VALIDATE CONSTRAINT reviews_passenger_fk;
ALTER TABLE passenger_reviews VALIDATE CONSTRAINT passenger_reviews_ride_fk;
ALTER TABLE passenger_reviews VALIDATE CONSTRAINT passenger_reviews_driver_fk;
ALTER TABLE passenger_reviews VALIDATE CONSTRAINT passenger_reviews_passenger_fk;
ALTER TABLE notifications VALIDATE CONSTRAINT notifications_user_fk;
ALTER TABLE driver_documents VALIDATE CONSTRAINT driver_documents_driver_fk;
ALTER TABLE driver_documents VALIDATE CONSTRAINT driver_documents_reviewer_fk;
ALTER TABLE refresh_sessions VALIDATE CONSTRAINT refresh_sessions_user_fk;
ALTER TABLE wallet_ledgers VALIDATE CONSTRAINT wallet_ledgers_driver_fk;
ALTER TABLE wallet_ledgers VALIDATE CONSTRAINT wallet_ledgers_ride_fk;
ALTER TABLE audit_events VALIDATE CONSTRAINT audit_events_actor_fk;

-- The old runner recorded (version, name, applied_at), while the native
-- runner uses app_schema_migrations with the standard dirty flag. Remove only
-- the known legacy shape after this baseline has completed successfully.
DO $migration$
DECLARE
    has_legacy_columns boolean;
BEGIN
    SELECT
        EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = current_schema()
              AND table_name = 'schema_migrations'
              AND column_name = 'name'
        )
        AND EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = current_schema()
              AND table_name = 'schema_migrations'
              AND column_name = 'applied_at'
        )
        AND NOT EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = current_schema()
              AND table_name = 'schema_migrations'
              AND column_name = 'dirty'
        )
    INTO has_legacy_columns;

    IF has_legacy_columns THEN
        EXECUTE format('DROP TABLE %I.%I', current_schema(), 'schema_migrations');
    END IF;
END
$migration$;

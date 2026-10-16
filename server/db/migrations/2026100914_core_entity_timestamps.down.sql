DO $migration$
BEGIN
    IF EXISTS (SELECT 1 FROM users WHERE updated_at <> created_at)
        OR EXISTS (SELECT 1 FROM driver_profiles WHERE updated_at <> created_at)
        OR EXISTS (SELECT 1 FROM passenger_profiles WHERE updated_at <> created_at)
        OR EXISTS (SELECT 1 FROM driver_wallet_accounts WHERE updated_at > created_at) THEN
        RAISE EXCEPTION 'cannot roll back core timestamps after post-migration updates were recorded';
    END IF;
END
$migration$;

ALTER TABLE users
    DROP COLUMN updated_at,
    DROP COLUMN created_at;

ALTER TABLE driver_profiles
    DROP COLUMN updated_at,
    DROP COLUMN created_at;

ALTER TABLE passenger_profiles
    DROP COLUMN updated_at,
    DROP COLUMN created_at;

ALTER TABLE driver_wallet_accounts
    DROP COLUMN created_at;

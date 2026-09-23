ALTER TABLE users
    ADD COLUMN IF NOT EXISTS account_status text NOT NULL DEFAULT 'active';

DO $migration$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'users_account_status_check'
          AND conrelid = 'users'::regclass
    ) THEN
        ALTER TABLE users
            ADD CONSTRAINT users_account_status_check
            CHECK (account_status IN ('active', 'suspended'));
    END IF;
END
$migration$;

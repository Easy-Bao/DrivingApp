ALTER TABLE refresh_sessions
    ADD COLUMN IF NOT EXISTS rotation_grace_until timestamptz;

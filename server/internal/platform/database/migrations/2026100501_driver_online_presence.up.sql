ALTER TABLE driver_profiles
    ADD COLUMN IF NOT EXISTS online_last_seen_at timestamptz;

UPDATE driver_profiles
SET online_last_seen_at = CURRENT_TIMESTAMP
WHERE is_online = true
  AND online_last_seen_at IS NULL;

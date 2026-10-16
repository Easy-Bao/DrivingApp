CREATE INDEX IF NOT EXISTS driver_profiles_online_last_seen_at_idx
    ON driver_profiles (online_last_seen_at, user_id)
    WHERE is_online = true;

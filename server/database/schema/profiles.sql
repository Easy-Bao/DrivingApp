CREATE TABLE driver_profiles (
    id serial PRIMARY KEY,
    user_id integer NOT NULL UNIQUE,
    name text NOT NULL,
    vehicle_type text NOT NULL,
    plate_number text NOT NULL,
    rating double precision NOT NULL DEFAULT 0 CHECK (rating BETWEEN 0 AND 5),
    is_online boolean NOT NULL DEFAULT false,
    online_last_seen_at timestamptz
);

CREATE TABLE passenger_profiles (
    id serial PRIMARY KEY,
    user_id integer NOT NULL UNIQUE,
    name text NOT NULL,
    address text,
    gender text NOT NULL DEFAULT 'Prefer not to say',
    avatar_storage_key text,
    avatar_content_type text,
    preferred_ride_type text
);

CREATE INDEX driver_profiles_online_last_seen_at_idx
    ON driver_profiles (online_last_seen_at, user_id)
    WHERE is_online = true;

\set ON_ERROR_STOP on

SELECT format('CREATE DATABASE %I OWNER %I', database_name, current_user)
FROM (
  VALUES
    ('passenger_db'),
    ('driver_db'),
    ('trip_db'),
    ('bidding_db'),
    ('chat_db'),
    ('fare_db'),
    ('location_db')
) AS local_databases(database_name)
WHERE NOT EXISTS (
  SELECT 1
  FROM pg_database
  WHERE datname = database_name
)
\gexec

\connect passenger_db

CREATE TABLE IF NOT EXISTS passengers (
  id text PRIMARY KEY,
  name text NOT NULL,
  email text NOT NULL,
  phone text NOT NULL,
  preferred_ride_type text,
  password_hash text NOT NULL DEFAULT '',
  is_verified boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

ALTER TABLE passengers
  ADD COLUMN IF NOT EXISTS password_hash text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS is_verified boolean NOT NULL DEFAULT false;

CREATE UNIQUE INDEX IF NOT EXISTS passengers_email_unique
  ON passengers (email);

\connect driver_db

CREATE TABLE IF NOT EXISTS drivers (
  id text PRIMARY KEY,
  name text NOT NULL,
  email text NOT NULL,
  phone text NOT NULL,
  vehicle_type text NOT NULL,
  plate_number text NOT NULL,
  password_hash text NOT NULL DEFAULT '',
  rating double precision NOT NULL DEFAULT 5.0,
  is_online boolean NOT NULL DEFAULT false,
  is_verified boolean NOT NULL DEFAULT false,
  lat double precision NOT NULL DEFAULT 7.828282,
  lng double precision NOT NULL DEFAULT 123.434343,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

ALTER TABLE drivers
  ADD COLUMN IF NOT EXISTS password_hash text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS is_verified boolean NOT NULL DEFAULT false;

CREATE UNIQUE INDEX IF NOT EXISTS drivers_email_unique
  ON drivers (email);

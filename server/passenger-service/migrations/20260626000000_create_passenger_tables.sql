-- Initial migration establishing passenger schema tables
CREATE TABLE passengers (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(50) NOT NULL,
    preferred_ride_type VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE ride_requests (
    id UUID PRIMARY KEY,
    passenger_id UUID NOT NULL REFERENCES passengers(id),
    ride_type VARCHAR(50) NOT NULL,
    pickup_latitude DOUBLE PRECISION NOT NULL,
    pickup_longitude DOUBLE PRECISION NOT NULL,
    pickup_name VARCHAR(255) NOT NULL,
    dropoff_latitude DOUBLE PRECISION NOT NULL,
    dropoff_longitude DOUBLE PRECISION NOT NULL,
    dropoff_name VARCHAR(255) NOT NULL,
    fare DOUBLE PRECISION NOT NULL,
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL
);

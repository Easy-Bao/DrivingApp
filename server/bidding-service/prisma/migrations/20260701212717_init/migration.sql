-- CreateTable
CREATE TABLE "bid_sessions" (
    "id" UUID NOT NULL,
    "passenger_id" UUID NOT NULL,
    "ride_type" TEXT NOT NULL,
    "pickup_latitude" DOUBLE PRECISION NOT NULL,
    "pickup_longitude" DOUBLE PRECISION NOT NULL,
    "pickup_name" TEXT NOT NULL,
    "dropoff_latitude" DOUBLE PRECISION NOT NULL,
    "dropoff_longitude" DOUBLE PRECISION NOT NULL,
    "dropoff_name" TEXT NOT NULL,
    "distance_km" DOUBLE PRECISION NOT NULL,
    "duration_minutes" DOUBLE PRECISION NOT NULL,
    "offered_fare" DOUBLE PRECISION NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'open',
    "accepted_driver_id" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "bid_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "driver_offers" (
    "id" UUID NOT NULL,
    "session_id" UUID NOT NULL,
    "driver_id" TEXT NOT NULL,
    "driver_name" TEXT NOT NULL,
    "plate_number" TEXT NOT NULL,
    "vehicle_type" TEXT NOT NULL,
    "proposed_fare" DOUBLE PRECISION NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "driver_offers_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "driver_offers" ADD CONSTRAINT "driver_offers_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "bid_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

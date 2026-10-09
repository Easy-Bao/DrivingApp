-- name: LockCompletedRideForCashSettlement :one
SELECT id, passenger_id, driver_id, status, fare_amount, ride_type,
    pickup_latitude, pickup_longitude, pickup_name,
    dropoff_latitude, dropoff_longitude, dropoff_name,
    distance_km, duration_minutes, driver_name, vehicle_type, plate_number,
    driver_rating, created_at, completed_at, arrived_at, waiting_until,
    cancelled_by, cancellation_reason, cancellation_responsibility,
    cancellation_details
FROM rides
WHERE id = $1
  AND driver_id = $2
  AND status = 'completed'
LIMIT 1
FOR UPDATE;

-- name: GetRideSettlementByRideID :one
SELECT id, ride_id, gross_fare, commission_bps, commission_amount,
    driver_payout_amount, payment_status, cash_received_at,
    cash_received_amount, cash_change_amount, cash_outcome, settled_at,
    created_at, updated_at
FROM ride_settlements
WHERE ride_id = $1
LIMIT 1
FOR UPDATE;

-- name: UpdateRideSettlementEconomics :one
UPDATE ride_settlements
SET commission_bps = sqlc.arg('commission_bps'),
    commission_amount = sqlc.arg('commission_amount'),
    driver_payout_amount = sqlc.arg('driver_payout_amount'),
    updated_at = CURRENT_TIMESTAMP
WHERE id = sqlc.arg('settlement_id')
RETURNING id, ride_id, gross_fare, commission_bps, commission_amount,
    driver_payout_amount, payment_status, cash_received_at,
    cash_received_amount, cash_change_amount, cash_outcome, settled_at,
    created_at, updated_at;

-- name: MarkRideSettlementOutcome :one
UPDATE ride_settlements
SET payment_status = sqlc.arg('payment_status'),
    cash_received_at = sqlc.arg('cash_received_at'),
    cash_received_amount = sqlc.arg('cash_received_amount'),
    cash_change_amount = sqlc.arg('cash_change_amount'),
    cash_outcome = sqlc.arg('cash_outcome'),
    settled_at = sqlc.arg('settled_at'),
    commission_bps = sqlc.arg('commission_bps'),
    commission_amount = sqlc.arg('commission_amount'),
    driver_payout_amount = sqlc.arg('driver_payout_amount'),
    updated_at = CURRENT_TIMESTAMP
WHERE id = sqlc.arg('settlement_id')
RETURNING id, ride_id, gross_fare, commission_bps, commission_amount,
    driver_payout_amount, payment_status, cash_received_at,
    cash_received_amount, cash_change_amount, cash_outcome, settled_at,
    created_at, updated_at;

-- name: GetDriverWalletAccountForUpdate :one
SELECT id, driver_id, balance, version, created_at, updated_at
FROM driver_wallet_accounts
WHERE driver_id = $1
LIMIT 1
FOR UPDATE;

-- name: CreateDriverWalletAccount :one
INSERT INTO driver_wallet_accounts (driver_id, balance)
VALUES ($1, $2)
RETURNING id, driver_id, balance, version, created_at, updated_at;

-- name: CreditDriverWalletAccount :one
UPDATE driver_wallet_accounts
SET balance = balance + $2,
    version = version + 1,
    updated_at = GREATEST(CURRENT_TIMESTAMP, created_at + interval '1 microsecond')
WHERE id = $1
RETURNING id, driver_id, balance, version, created_at, updated_at;

-- name: CreateWalletLedger :execrows
INSERT INTO wallet_ledgers (
    driver_id, ride_id, amount, commission_amount, kind, idempotency_key
)
VALUES ($1, $2, $3, $4, $5, $6)
ON CONFLICT (idempotency_key) DO NOTHING;

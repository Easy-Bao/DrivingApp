-- name: GetRideByID :one
SELECT sqlc.embed(ride),
    COALESCE(settlement.payment_status, 'unpaid') AS payment_status,
    COALESCE(settlement.cash_received_amount, 0)::bigint AS cash_received_amount,
    COALESCE(settlement.cash_change_amount, 0)::bigint AS cash_change_amount,
    COALESCE(settlement.cash_outcome, 'unpaid') AS cash_outcome,
    settlement.commission_bps,
    COALESCE(settlement.commission_amount, 0)::bigint AS commission_amount,
    COALESCE(settlement.driver_payout_amount, 0)::bigint AS driver_payout_amount
FROM rides AS ride
LEFT JOIN ride_settlements AS settlement ON settlement.ride_id = ride.id
WHERE ride.id = $1
LIMIT 1;

-- name: ListActiveRidesForDriver :many
SELECT sqlc.embed(ride),
    COALESCE(settlement.payment_status, 'unpaid') AS payment_status,
    COALESCE(settlement.cash_received_amount, 0)::bigint AS cash_received_amount,
    COALESCE(settlement.cash_change_amount, 0)::bigint AS cash_change_amount,
    COALESCE(settlement.cash_outcome, 'unpaid') AS cash_outcome,
    settlement.commission_bps,
    COALESCE(settlement.commission_amount, 0)::bigint AS commission_amount,
    COALESCE(settlement.driver_payout_amount, 0)::bigint AS driver_payout_amount
FROM rides AS ride
LEFT JOIN ride_settlements AS settlement ON settlement.ride_id = ride.id
WHERE ride.driver_id = $1
  AND ride.status IN ('assigned', 'accepted', 'arrived', 'in_transit')
ORDER BY ride.id;

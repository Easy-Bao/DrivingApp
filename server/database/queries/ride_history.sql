-- name: ListDriverRides :many
SELECT sqlc.embed(ride),
    COALESCE(settlement.payment_status, 'unpaid') AS payment_status,
    COALESCE(settlement.cash_received_amount, 0)::bigint AS cash_received_amount,
    COALESCE(settlement.cash_change_amount, 0)::bigint AS cash_change_amount,
    COALESCE(settlement.cash_outcome, 'unpaid') AS cash_outcome,
    settlement.commission_bps,
    COALESCE(settlement.commission_amount, 0)::bigint AS commission_amount,
    COALESCE(settlement.driver_payout_amount, 0)::bigint AS driver_payout_amount,
    COALESCE(NULLIF(passenger_profile.name, ''), user_account.name, '') AS passenger_name,
    COALESCE(user_account.phone, '') AS passenger_phone,
    passenger_review.rating AS passenger_rating,
    passenger_review.comment AS passenger_feedback
FROM rides AS ride
LEFT JOIN ride_settlements AS settlement ON settlement.ride_id = ride.id
LEFT JOIN users AS user_account ON user_account.id = ride.passenger_id
LEFT JOIN passenger_profiles AS passenger_profile ON passenger_profile.user_id = ride.passenger_id
LEFT JOIN reviews AS passenger_review ON passenger_review.ride_id = ride.id
WHERE ride.driver_id = sqlc.arg('driver_id')
  AND (
      sqlc.arg('active_only')::boolean = false
      OR ride.status IN ('assigned', 'accepted', 'arrived', 'in_transit')
  )
ORDER BY ride.created_at DESC, ride.id DESC
LIMIT sqlc.arg('limit')::int
OFFSET sqlc.arg('offset')::int;

-- name: ListPassengerRides :many
SELECT sqlc.embed(ride),
    COALESCE(settlement.payment_status, 'unpaid') AS payment_status,
    COALESCE(settlement.cash_received_amount, 0)::bigint AS cash_received_amount,
    COALESCE(settlement.cash_change_amount, 0)::bigint AS cash_change_amount,
    COALESCE(settlement.cash_outcome, 'unpaid') AS cash_outcome,
    settlement.commission_bps,
    COALESCE(settlement.commission_amount, 0)::bigint AS commission_amount,
    COALESCE(settlement.driver_payout_amount, 0)::bigint AS driver_payout_amount,
    COALESCE(driver_profile.name, '') AS driver_profile_name,
    COALESCE(driver_profile.vehicle_type, '') AS driver_profile_vehicle_type,
    COALESCE(driver_profile.plate_number, '') AS driver_profile_plate_number
FROM rides AS ride
LEFT JOIN ride_settlements AS settlement ON settlement.ride_id = ride.id
LEFT JOIN driver_profiles AS driver_profile ON driver_profile.user_id = ride.driver_id
WHERE ride.passenger_id = sqlc.arg('passenger_id')
ORDER BY ride.created_at DESC, ride.id DESC
LIMIT sqlc.arg('limit')::int
OFFSET sqlc.arg('offset')::int;

-- name: ListRecentPassengerRides :many
SELECT sqlc.embed(ride),
    COALESCE(settlement.payment_status, 'unpaid') AS payment_status,
    COALESCE(settlement.cash_received_amount, 0)::bigint AS cash_received_amount,
    COALESCE(settlement.cash_change_amount, 0)::bigint AS cash_change_amount,
    COALESCE(settlement.cash_outcome, 'unpaid') AS cash_outcome,
    settlement.commission_bps,
    COALESCE(settlement.commission_amount, 0)::bigint AS commission_amount,
    COALESCE(settlement.driver_payout_amount, 0)::bigint AS driver_payout_amount,
    COALESCE(driver_profile.name, '') AS driver_profile_name,
    COALESCE(driver_profile.vehicle_type, '') AS driver_profile_vehicle_type,
    COALESCE(driver_profile.plate_number, '') AS driver_profile_plate_number
FROM rides AS ride
LEFT JOIN ride_settlements AS settlement ON settlement.ride_id = ride.id
LEFT JOIN driver_profiles AS driver_profile ON driver_profile.user_id = ride.driver_id
WHERE ride.passenger_id = sqlc.arg('passenger_id')
ORDER BY ride.id DESC
LIMIT sqlc.arg('limit')::int;

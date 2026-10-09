-- name: GetDriverStats :one
SELECT
    COUNT(*)::bigint AS total_trips,
    COUNT(*) FILTER (WHERE r.status = 'completed')::bigint AS completed_trips,
    COUNT(*) FILTER (
        WHERE r.status IN ('requested', 'assigned', 'accepted', 'arrived', 'in_transit')
    )::bigint AS active_trips,
    COALESCE(SUM(settlement.driver_payout_amount) FILTER (WHERE r.status = 'completed'), 0)::bigint
        AS total_earnings_amount,
    COUNT(*) FILTER (
        WHERE r.status = 'completed'
          AND (
              (r.completed_at >= sqlc.arg('day_start') AND r.completed_at < sqlc.arg('day_end'))
              OR (
                  r.completed_at IS NULL
                  AND r.created_at >= sqlc.arg('day_start')
                  AND r.created_at < sqlc.arg('day_end')
              )
          )
    )::bigint AS today_completed_trips,
    COALESCE(SUM(settlement.driver_payout_amount) FILTER (
        WHERE r.status = 'completed'
          AND (
              (r.completed_at >= sqlc.arg('day_start') AND r.completed_at < sqlc.arg('day_end'))
              OR (
                  r.completed_at IS NULL
                  AND r.created_at >= sqlc.arg('day_start')
                  AND r.created_at < sqlc.arg('day_end')
              )
          )
    ), 0)::bigint AS today_earnings_amount,
    COALESCE((
        SELECT AVG(review.rating)
        FROM reviews AS review
        WHERE review.driver_id = sqlc.arg('driver_id')
    ), 0)::double precision AS average_rating
    ,(
        SELECT COUNT(*)::bigint
        FROM reviews AS review
        WHERE review.driver_id = sqlc.arg('driver_id')
          AND review.rating >= 1
          AND review.rating < 2
    ) AS one_star_count
    ,(
        SELECT COUNT(*)::bigint
        FROM reviews AS review
        WHERE review.driver_id = sqlc.arg('driver_id')
          AND review.rating >= 2
          AND review.rating < 3
    ) AS two_star_count
    ,(
        SELECT COUNT(*)::bigint
        FROM reviews AS review
        WHERE review.driver_id = sqlc.arg('driver_id')
          AND review.rating >= 3
          AND review.rating < 4
    ) AS three_star_count
    ,(
        SELECT COUNT(*)::bigint
        FROM reviews AS review
        WHERE review.driver_id = sqlc.arg('driver_id')
          AND review.rating >= 4
          AND review.rating < 5
    ) AS four_star_count
    ,(
        SELECT COUNT(*)::bigint
        FROM reviews AS review
        WHERE review.driver_id = sqlc.arg('driver_id')
          AND review.rating >= 5
          AND review.rating <= 5
    ) AS five_star_count
    ,(
        SELECT COUNT(*)::bigint
        FROM rides AS standing_ride
        WHERE standing_ride.driver_id = sqlc.arg('driver_id')
          AND standing_ride.status IN ('completed', 'cancelled')
    ) AS standing_settled_trips
    ,(
        SELECT COUNT(*)::bigint
        FROM rides AS standing_ride
        WHERE standing_ride.driver_id = sqlc.arg('driver_id')
          AND standing_ride.status = 'cancelled'
          AND standing_ride.cancellation_responsibility = 'driver_fault'
    ) AS driver_fault_cancellation_count
    ,(
        SELECT COUNT(*)::bigint
        FROM rides AS standing_ride
        WHERE standing_ride.driver_id = sqlc.arg('driver_id')
          AND standing_ride.status = 'cancelled'
          AND standing_ride.cancellation_responsibility = 'passenger_fault'
    ) AS passenger_fault_cancellation_count
    ,(
        SELECT COUNT(*)::bigint
        FROM rides AS standing_ride
        WHERE standing_ride.driver_id = sqlc.arg('driver_id')
          AND standing_ride.status = 'cancelled'
          AND standing_ride.cancellation_responsibility = 'system_fault'
    ) AS system_fault_cancellation_count
    ,(
        SELECT COUNT(*)::bigint
        FROM rides AS standing_ride
        WHERE standing_ride.driver_id = sqlc.arg('driver_id')
          AND standing_ride.status = 'cancelled'
          AND standing_ride.cancellation_responsibility = 'no_fault'
    ) AS no_fault_cancellation_count
    ,(
        SELECT COUNT(*)::bigint
        FROM rides AS standing_ride
        WHERE standing_ride.driver_id = sqlc.arg('driver_id')
          AND standing_ride.status = 'cancelled'
          AND standing_ride.cancellation_responsibility = 'safety_related'
    ) AS safety_related_cancellation_count
    ,(
        SELECT COUNT(*)::bigint
        FROM rides AS standing_ride
        WHERE standing_ride.driver_id = sqlc.arg('driver_id')
          AND standing_ride.status = 'cancelled'
          AND standing_ride.cancellation_responsibility = 'pending_review'
    ) AS pending_review_cancellation_count
    ,(
        SELECT COUNT(*)::bigint
        FROM rides AS standing_ride
        WHERE standing_ride.driver_id = sqlc.arg('driver_id')
          AND standing_ride.status = 'cancelled'
          AND standing_ride.cancellation_responsibility = 'admin_override'
    ) AS admin_override_cancellation_count
FROM rides AS r
LEFT JOIN ride_settlements AS settlement ON settlement.ride_id = r.id
WHERE r.driver_id = sqlc.arg('driver_id');

-- name: ListDriverEarnings :many
SELECT ride.created_at, ride.completed_at,
    COALESCE(settlement.driver_payout_amount, 0)::bigint AS driver_payout_amount
FROM rides AS ride
LEFT JOIN ride_settlements AS settlement ON settlement.ride_id = ride.id
WHERE ride.driver_id = sqlc.arg('driver_id')
  AND ride.status = 'completed'
  AND (
      (
          ride.completed_at IS NOT NULL
          AND ride.completed_at >= sqlc.arg('month_start')
          AND ride.completed_at < sqlc.arg('month_end')
      )
      OR (
          ride.completed_at IS NULL
          AND ride.created_at >= sqlc.arg('month_start')
          AND ride.created_at < sqlc.arg('month_end')
      )
  );

-- name: GetPassengerActivitySummary :one
SELECT
    COALESCE(SUM(r.fare_amount) FILTER (
        WHERE r.status = 'completed'
          AND (
              (r.completed_at >= sqlc.arg('week_start') AND r.completed_at < sqlc.arg('week_end'))
              OR (
                  r.completed_at IS NULL
                  AND r.created_at >= sqlc.arg('week_start')
                  AND r.created_at < sqlc.arg('week_end')
              )
          )
    ), 0)::bigint AS this_week_fare_amount,
    COUNT(*) FILTER (
        WHERE r.status = 'completed'
          AND (
              (r.completed_at >= sqlc.arg('week_start') AND r.completed_at < sqlc.arg('week_end'))
              OR (
                  r.completed_at IS NULL
                  AND r.created_at >= sqlc.arg('week_start')
                  AND r.created_at < sqlc.arg('week_end')
              )
          )
    )::bigint AS this_week_completed_rides
FROM rides AS r
WHERE r.passenger_id = sqlc.arg('passenger_id');

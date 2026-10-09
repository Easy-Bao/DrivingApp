-- name: GetDriverStats :one
WITH rating_stats AS (
    SELECT
        AVG(review.rating) AS average_rating,
        COUNT(*) FILTER (WHERE review.rating >= 1 AND review.rating < 2)::bigint AS one_star_count,
        COUNT(*) FILTER (WHERE review.rating >= 2 AND review.rating < 3)::bigint AS two_star_count,
        COUNT(*) FILTER (WHERE review.rating >= 3 AND review.rating < 4)::bigint AS three_star_count,
        COUNT(*) FILTER (WHERE review.rating >= 4 AND review.rating < 5)::bigint AS four_star_count,
        COUNT(*) FILTER (WHERE review.rating = 5)::bigint AS five_star_count
    FROM reviews AS review
    WHERE review.driver_id = sqlc.arg('driver_id')::int
)
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
    COALESCE(rating_stats.average_rating, 0)::double precision AS average_rating,
    rating_stats.one_star_count,
    rating_stats.two_star_count,
    rating_stats.three_star_count,
    rating_stats.four_star_count,
    rating_stats.five_star_count,
    COUNT(*) FILTER (WHERE r.status IN ('completed', 'cancelled'))::bigint AS standing_settled_trips,
    COUNT(*) FILTER (
        WHERE r.status = 'cancelled'
          AND r.cancellation_responsibility = 'driver_fault'
    )::bigint AS driver_fault_cancellation_count,
    COUNT(*) FILTER (
        WHERE r.status = 'cancelled'
          AND r.cancellation_responsibility = 'passenger_fault'
    )::bigint AS passenger_fault_cancellation_count,
    COUNT(*) FILTER (
        WHERE r.status = 'cancelled'
          AND r.cancellation_responsibility = 'system_fault'
    )::bigint AS system_fault_cancellation_count,
    COUNT(*) FILTER (
        WHERE r.status = 'cancelled'
          AND r.cancellation_responsibility = 'no_fault'
    )::bigint AS no_fault_cancellation_count,
    COUNT(*) FILTER (
        WHERE r.status = 'cancelled'
          AND r.cancellation_responsibility = 'safety_related'
    )::bigint AS safety_related_cancellation_count,
    COUNT(*) FILTER (
        WHERE r.status = 'cancelled'
          AND r.cancellation_responsibility = 'pending_review'
    )::bigint AS pending_review_cancellation_count,
    COUNT(*) FILTER (
        WHERE r.status = 'cancelled'
          AND r.cancellation_responsibility = 'admin_override'
    )::bigint AS admin_override_cancellation_count
FROM rides AS r
LEFT JOIN ride_settlements AS settlement ON settlement.ride_id = r.id
CROSS JOIN rating_stats
WHERE r.driver_id = sqlc.arg('driver_id')::int;

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

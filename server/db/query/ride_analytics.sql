-- name: GetDriverStats :one
SELECT
    COUNT(*)::bigint AS total_trips,
    COUNT(*) FILTER (WHERE r.status = 'completed')::bigint AS completed_trips,
    COUNT(*) FILTER (
        WHERE r.status IN ('requested', 'assigned', 'accepted', 'arrived', 'in_transit')
    )::bigint AS active_trips,
    COALESCE(SUM(r.driver_payout_centavos) FILTER (WHERE r.status = 'completed'), 0)::bigint
        AS total_earnings_centavos,
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
    COALESCE(SUM(r.driver_payout_centavos) FILTER (
        WHERE r.status = 'completed'
          AND (
              (r.completed_at >= sqlc.arg('day_start') AND r.completed_at < sqlc.arg('day_end'))
              OR (
                  r.completed_at IS NULL
                  AND r.created_at >= sqlc.arg('day_start')
                  AND r.created_at < sqlc.arg('day_end')
              )
          )
    ), 0)::bigint AS today_earnings_centavos,
    COALESCE((
        SELECT AVG(review.rating)
        FROM reviews AS review
        WHERE review.driver_id = sqlc.arg('driver_id')
    ), 0)::double precision AS average_rating
FROM rides AS r
WHERE r.driver_id = sqlc.arg('driver_id');

-- name: ListDriverEarnings :many
SELECT created_at, completed_at, driver_payout_centavos
FROM rides
WHERE driver_id = sqlc.arg('driver_id')
  AND status = 'completed'
  AND (
      (
          completed_at IS NOT NULL
          AND completed_at >= sqlc.arg('month_start')
          AND completed_at < sqlc.arg('month_end')
      )
      OR (
          completed_at IS NULL
          AND created_at >= sqlc.arg('month_start')
          AND created_at < sqlc.arg('month_end')
      )
  );

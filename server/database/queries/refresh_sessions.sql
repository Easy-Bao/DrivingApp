-- name: CreateRefreshSession :exec
INSERT INTO refresh_sessions (user_id, token_hash, expires_at)
VALUES ($1, $2, $3);

-- name: GetActiveRefreshSession :one
SELECT id, user_id, token_hash, expires_at
FROM refresh_sessions
WHERE token_hash = $1
  AND (revoked_at IS NULL OR rotation_grace_until > $2)
  AND expires_at > $2
LIMIT 1;

-- name: GetActiveRefreshSessionForUpdate :one
SELECT id, user_id, token_hash, expires_at
FROM refresh_sessions
WHERE token_hash = $1
  AND (revoked_at IS NULL OR rotation_grace_until > $2)
  AND expires_at > $2
LIMIT 1
FOR UPDATE;

-- name: RevokeRefreshSessionByID :execrows
UPDATE refresh_sessions
SET revoked_at = $2,
    last_used_at = $2,
    rotation_grace_until = COALESCE(
        rotation_grace_until,
        $2 + INTERVAL '30 seconds'
    )
WHERE id = $1
  AND (revoked_at IS NULL OR rotation_grace_until > $2);

-- name: RevokeRefreshSession :exec
UPDATE refresh_sessions
SET revoked_at = $2,
    rotation_grace_until = NULL
WHERE token_hash = $1
  AND (revoked_at IS NULL OR rotation_grace_until > $2);

-- name: RevokeUserRefreshSessions :exec
UPDATE refresh_sessions
SET revoked_at = $2,
    rotation_grace_until = NULL
WHERE user_id = $1
  AND (revoked_at IS NULL OR rotation_grace_until > $2);

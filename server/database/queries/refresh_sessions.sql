-- name: CreateRefreshSession :exec
INSERT INTO refresh_sessions (user_id, token_hash, expires_at)
VALUES ($1, $2, $3);

-- name: GetActiveRefreshSession :one
SELECT id, user_id, token_hash, expires_at
FROM refresh_sessions
WHERE token_hash = $1
  AND revoked_at IS NULL
  AND expires_at > $2
LIMIT 1;

-- name: GetActiveRefreshSessionForUpdate :one
SELECT id, user_id, token_hash, expires_at
FROM refresh_sessions
WHERE token_hash = $1
  AND revoked_at IS NULL
  AND expires_at > $2
LIMIT 1
FOR UPDATE;

-- name: RevokeRefreshSessionByID :execrows
UPDATE refresh_sessions
SET revoked_at = $2, last_used_at = $2
WHERE id = $1
  AND revoked_at IS NULL;

-- name: RevokeRefreshSession :exec
UPDATE refresh_sessions
SET revoked_at = $2
WHERE token_hash = $1
  AND revoked_at IS NULL;

-- name: RevokeUserRefreshSessions :exec
UPDATE refresh_sessions
SET revoked_at = $2
WHERE user_id = $1
  AND revoked_at IS NULL;

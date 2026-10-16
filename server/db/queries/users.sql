-- name: GetUserByEmail :one
SELECT id, name, phone, email, password_hash, role, is_verified,
    account_status, created_at, updated_at
FROM users
WHERE email = $1
LIMIT 1;

-- name: GetUserByID :one
SELECT id, name, phone, email, password_hash, role, is_verified,
    account_status, created_at, updated_at
FROM users
WHERE id = $1
LIMIT 1;

-- name: UpdateUserEmail :execrows
UPDATE users
SET email = sqlc.arg('new_email'),
    is_verified = TRUE,
    updated_at = CURRENT_TIMESTAMP
WHERE id = sqlc.arg('user_id')
  AND email = sqlc.arg('expected_email')
  AND is_verified = TRUE;

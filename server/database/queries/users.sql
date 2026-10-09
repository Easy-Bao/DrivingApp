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

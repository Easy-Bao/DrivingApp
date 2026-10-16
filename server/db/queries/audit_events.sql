-- name: CreateAuditEvent :one
INSERT INTO audit_events (
    actor_id,
    action,
    target_type,
    target_id,
    outcome,
    request_id
)
VALUES (
    sqlc.arg('actor_id'),
    sqlc.arg('action'),
    sqlc.arg('target_type'),
    sqlc.arg('target_id'),
    sqlc.arg('outcome'),
    sqlc.arg('request_id')
)
RETURNING id, actor_id, action, target_type, target_id, outcome, request_id, created_at;

-- name: UpsertChatRoom :exec
INSERT INTO chat_rooms (room_id, passenger_id, driver_id)
VALUES ($1, $2, $3)
ON CONFLICT (room_id) DO NOTHING;

-- name: MigrateChatRoomState :exec
INSERT INTO chat_rooms (
    room_id, passenger_id, driver_id, locked, passenger_read_through, driver_read_through
)
VALUES (
    $1,
    $2,
    $3,
    $4,
    sqlc.narg('passenger_read_through')::timestamptz,
    sqlc.narg('driver_read_through')::timestamptz
)
ON CONFLICT (room_id) DO UPDATE
SET locked = chat_rooms.locked OR EXCLUDED.locked,
    passenger_read_through = CASE
        WHEN chat_rooms.passenger_read_through IS NULL THEN EXCLUDED.passenger_read_through
        WHEN EXCLUDED.passenger_read_through IS NULL THEN chat_rooms.passenger_read_through
        ELSE GREATEST(chat_rooms.passenger_read_through, EXCLUDED.passenger_read_through)
    END,
    driver_read_through = CASE
        WHEN chat_rooms.driver_read_through IS NULL THEN EXCLUDED.driver_read_through
        WHEN EXCLUDED.driver_read_through IS NULL THEN chat_rooms.driver_read_through
        ELSE GREATEST(chat_rooms.driver_read_through, EXCLUDED.driver_read_through)
    END,
    updated_at = CURRENT_TIMESTAMP;

-- name: GetChatRoom :one
SELECT room_id, passenger_id, driver_id, locked, passenger_read_through, driver_read_through, created_at, updated_at
FROM chat_rooms
WHERE room_id = $1
LIMIT 1;

-- name: LockChatRoomForAppend :one
SELECT room_id, passenger_id, driver_id, locked, passenger_read_through, driver_read_through
FROM chat_rooms
WHERE room_id = $1
LIMIT 1
FOR UPDATE;

-- name: InsertChatMessage :exec
INSERT INTO chat_messages (id, room_id, sender_id, body, image_key, created_at)
VALUES ($1, $2, $3, $4, $5, $6)
ON CONFLICT (id) DO NOTHING;

-- name: ListChatMessagesByRoom :many
SELECT id, room_id, sender_id, body, image_key, created_at
FROM (
    SELECT id, room_id, sender_id, body, image_key, created_at
    FROM chat_messages
    WHERE room_id = $1
    ORDER BY created_at DESC, id DESC
    LIMIT sqlc.arg('limit')::int
) AS recent
ORDER BY created_at ASC, id ASC;

-- name: GetChatMessageByRoomAndID :one
SELECT id, room_id, sender_id, body, image_key, created_at
FROM chat_messages
WHERE room_id = $1
  AND id = $2
LIMIT 1;

-- name: LockChatRoom :exec
UPDATE chat_rooms
SET locked = true,
    updated_at = CURRENT_TIMESTAMP
WHERE room_id = $1;

-- name: MarkChatRoomRead :exec
UPDATE chat_rooms
SET passenger_read_through = CASE
        WHEN passenger_id = sqlc.arg('user_id')::text THEN
            CASE
                WHEN passenger_read_through IS NULL OR passenger_read_through < sqlc.arg('read_through')::timestamptz
                THEN sqlc.arg('read_through')::timestamptz
                ELSE passenger_read_through
            END
        ELSE passenger_read_through
    END,
    driver_read_through = CASE
        WHEN driver_id = sqlc.arg('user_id')::text THEN
            CASE
                WHEN driver_read_through IS NULL OR driver_read_through < sqlc.arg('read_through')::timestamptz
                THEN sqlc.arg('read_through')::timestamptz
                ELSE driver_read_through
            END
        ELSE driver_read_through
    END,
    updated_at = CURRENT_TIMESTAMP
WHERE room_id = sqlc.arg('room_id')::text;

CREATE TABLE IF NOT EXISTS chat_rooms (
    room_id text PRIMARY KEY,
    passenger_id text NOT NULL,
    driver_id text NOT NULL,
    locked boolean NOT NULL DEFAULT false,
    passenger_read_through timestamptz,
    driver_read_through timestamptz,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS chat_messages (
    id text PRIMARY KEY,
    room_id text NOT NULL,
    sender_id text NOT NULL,
    body text NOT NULL DEFAULT '',
    image_key text NOT NULL DEFAULT '',
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chat_messages_room_fk
        FOREIGN KEY (room_id) REFERENCES chat_rooms (room_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS chat_messages_room_created_id_idx
    ON chat_messages (room_id, created_at ASC, id ASC);

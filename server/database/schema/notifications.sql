CREATE TABLE notifications (
    id serial PRIMARY KEY,
    user_id integer NOT NULL,
    type text NOT NULL DEFAULT 'general',
    title text NOT NULL,
    body text NOT NULL,
    is_read boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT notifications_user_fk
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX notification_user_id_created_at
    ON notifications (user_id, created_at);

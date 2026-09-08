CREATE TABLE audit_events (
    id serial PRIMARY KEY,
    actor_id integer NOT NULL,
    action text NOT NULL,
    target_type text NOT NULL,
    target_id text,
    outcome text NOT NULL,
    request_id text NOT NULL UNIQUE,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX auditevent_actor_id_created_at
    ON audit_events (actor_id, created_at);

CREATE TABLE refresh_sessions (
    id serial PRIMARY KEY,
    user_id integer NOT NULL,
    token_hash varchar(64) NOT NULL UNIQUE,
    expires_at timestamptz NOT NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_used_at timestamptz,
    revoked_at timestamptz
);

CREATE INDEX refreshsession_user_id_expires_at
    ON refresh_sessions (user_id, expires_at);

CREATE INDEX refreshsession_expires_at_revoked_at
    ON refresh_sessions (expires_at, revoked_at);

CREATE TABLE users (
    id serial PRIMARY KEY,
    name text DEFAULT '',
    phone text NOT NULL UNIQUE,
    email text NOT NULL UNIQUE,
    password_hash text NOT NULL,
    role text NOT NULL,
    is_verified boolean NOT NULL DEFAULT false
);

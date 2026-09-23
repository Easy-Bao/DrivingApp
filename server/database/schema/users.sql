CREATE TABLE users (
    id serial PRIMARY KEY,
    name text DEFAULT '',
    phone text NOT NULL UNIQUE,
    email text NOT NULL UNIQUE,
    password_hash text NOT NULL,
    role text NOT NULL,
    is_verified boolean NOT NULL DEFAULT false,
    account_status text NOT NULL DEFAULT 'active',
    CONSTRAINT users_account_status_check CHECK (account_status IN ('active', 'suspended'))
);

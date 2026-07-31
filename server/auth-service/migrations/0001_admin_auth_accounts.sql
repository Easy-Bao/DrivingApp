CREATE TABLE admin_auth_accounts (
  singleton_key boolean PRIMARY KEY DEFAULT true,
  id text UNIQUE NOT NULL,
  email text UNIQUE NOT NULL,
  password_hash text NOT NULL,
  failed_login_attempts integer NOT NULL DEFAULT 0,
  locked_until timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT admin_auth_accounts_singleton_key_check CHECK (singleton_key = true),
  CONSTRAINT admin_auth_accounts_failed_login_attempts_check CHECK (failed_login_attempts >= 0)
);

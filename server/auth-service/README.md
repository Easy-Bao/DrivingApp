# Auth service

## Admin owner setup

The dashboard has one private owner account. There is no admin registration,
email reset, or default credential.

1. Configure `JWT_SECRET` and `AUTH_DB_URL` (or the documented database fallback).
2. Apply `migrations/0001_admin_auth_accounts.sql` with the deployment's normal
   PostgreSQL migration tool. For example:

   ```sh
   psql "$AUTH_DB_URL" -v ON_ERROR_STOP=1 -f migrations/0001_admin_auth_accounts.sql
   ```

   With the local Docker Compose stack from PowerShell:

   ```powershell
   Get-Content -Raw server/auth-service/migrations/0001_admin_auth_accounts.sql |
     docker compose exec -T postgres-db sh -c 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"'
   ```

3. From an interactive terminal, run:

   ```sh
   bun run owner:provision
   ```

   Or run it inside the Compose service:

   ```sh
   docker compose exec auth-service bun run owner:provision
   ```

The command creates the owner when none exists. Running it again with the same
email rotates the password and clears a login lock. It refuses to replace an
owner that uses a different email.

Admin login is `POST /auth/admin/login` with `email` and `password`. A successful
login returns an eight-hour JWT with `role: "admin"`.

To roll back before the admin dashboard is used, first back up the database and
then drop `admin_auth_accounts`. Do not drop the table after owner activity
without an approved data-retention plan.

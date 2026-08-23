package migration

import (
	"context"
	"database/sql"
)

func applyUserRoleMemberships(ctx context.Context, connection *sql.Conn) error {
	return executeStatements(ctx, connection, userRoleMembershipStatements)
}

var userRoleMembershipStatements = []string{
	`DO $migration$
	DECLARE
		user_id_type TEXT;
	BEGIN
		IF to_regclass('public.user_roles') IS NULL THEN
			SELECT format_type(attribute.atttypid, attribute.atttypmod)
			INTO user_id_type
			FROM pg_attribute AS attribute
			JOIN pg_class AS relation ON relation.oid = attribute.attrelid
			JOIN pg_namespace AS namespace ON namespace.oid = relation.relnamespace
			WHERE namespace.nspname = 'public'
			  AND relation.relname = 'users'
			  AND attribute.attname = 'id'
			  AND attribute.attnum > 0
			  AND NOT attribute.attisdropped;
			IF user_id_type IS NULL THEN
				RAISE EXCEPTION 'users.id type is unavailable';
			END IF;
			EXECUTE format(
				'CREATE TABLE user_roles (
					id BIGSERIAL PRIMARY KEY,
					user_id %s NOT NULL,
					role VARCHAR(16) NOT NULL,
					created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
				)',
				user_id_type
			);
		END IF;
	END
	$migration$`,
	`CREATE UNIQUE INDEX IF NOT EXISTS userrole_user_id_role ON user_roles (user_id, role)`,
	`ALTER TABLE user_roles DROP CONSTRAINT IF EXISTS user_roles_role_check`,
	`ALTER TABLE user_roles ADD CONSTRAINT user_roles_role_check CHECK (role IN ('passenger', 'driver'))`,
	`INSERT INTO user_roles (user_id, role)
	SELECT id, role
	FROM users
	WHERE role IN ('passenger', 'driver')
	ON CONFLICT (user_id, role) DO NOTHING`,
	addForeignKey("user_roles_user_fk", "user_roles", "user_id", "users", "id", "CASCADE"),
	validateForeignKey("user_roles", "user_roles_user_fk"),
}

package migration

import (
	"context"

	"entgo.io/ent/dialect"
)

func applyPassengerProfileAttributes(ctx context.Context, connection dialect.ExecQuerier) error {
	statements := []string{
		`ALTER TABLE passenger_profiles ADD COLUMN IF NOT EXISTS gender VARCHAR(32) NOT NULL DEFAULT 'Prefer not to say'`,
		`ALTER TABLE passenger_profiles ADD COLUMN IF NOT EXISTS avatar_storage_key VARCHAR(160)`,
		`ALTER TABLE passenger_profiles ADD COLUMN IF NOT EXISTS avatar_content_type VARCHAR(64)`,
		`UPDATE passenger_profiles SET gender = 'Prefer not to say' WHERE gender IS NULL OR gender NOT IN ('Female', 'Male', 'Non-binary', 'Prefer not to say')`,
		`ALTER TABLE passenger_profiles ALTER COLUMN gender SET DEFAULT 'Prefer not to say'`,
		`ALTER TABLE passenger_profiles ALTER COLUMN gender SET NOT NULL`,
		`ALTER TABLE passenger_profiles DROP CONSTRAINT IF EXISTS passenger_profiles_gender_check`,
		`ALTER TABLE passenger_profiles ADD CONSTRAINT passenger_profiles_gender_check CHECK (gender IN ('Female', 'Male', 'Non-binary', 'Prefer not to say'))`,
		`ALTER TABLE passenger_profiles DROP CONSTRAINT IF EXISTS passenger_profiles_avatar_content_type_check`,
		`ALTER TABLE passenger_profiles ADD CONSTRAINT passenger_profiles_avatar_content_type_check CHECK (avatar_content_type IS NULL OR avatar_content_type IN ('image/jpeg', 'image/png'))`,
	}
	return executeStatements(ctx, connection, statements)
}

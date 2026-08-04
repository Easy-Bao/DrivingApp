package migration

import (
	"context"
	"database/sql"
	"fmt"
)

// Preserve incompatible legacy tables under an explicit namespace so Ent can
// create the new modular schema without destructive drops or type coercion.
func PreserveLegacyTables(ctx context.Context, database *sql.DB) error {
	for _, table := range []string{"rides", "bid_sessions", "reviews", "notifications"} {
		var dataType string
		err := database.QueryRowContext(ctx, `
			SELECT data_type
			FROM information_schema.columns
			WHERE table_schema = 'public' AND table_name = $1 AND column_name = 'id'`, table).Scan(&dataType)
		if err == sql.ErrNoRows || dataType == "" {
			continue
		}
		if err != nil {
			return err
		}
		if dataType != "integer" && dataType != "bigint" {
			legacyName := "legacy_" + table
			var exists bool
			if err := database.QueryRowContext(ctx, `SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = $1)`, legacyName).Scan(&exists); err != nil {
				return err
			}
			if exists {
				return fmt.Errorf("incompatible legacy table %q and preserved table %q already exists", table, legacyName)
			}
			if _, err := database.ExecContext(ctx, `ALTER TABLE public."`+table+`" RENAME TO "`+legacyName+`"`); err != nil {
				return err
			}
		}
	}
	return nil
}

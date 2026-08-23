package migration

import (
	"context"
	"database/sql"
	"fmt"
)

type rowQuerier interface {
	QueryRowContext(context.Context, string, ...any) *sql.Row
}

func ValidateCompatibleSchema(ctx context.Context, database rowQuerier) error {
	for _, table := range []string{
		"users",
		"rides",
		"bid_sessions",
		"reviews",
		"notifications",
	} {
		var dataType string
		err := database.QueryRowContext(ctx, `
			SELECT data_type
			FROM information_schema.columns
			WHERE table_schema = 'public'
			  AND table_name = $1
			  AND column_name = 'id'`, table).Scan(&dataType)
		if err == sql.ErrNoRows {
			continue
		}
		if err != nil {
			return fmt.Errorf("inspect %s.id: %w", table, err)
		}
		if dataType != "integer" && dataType != "bigint" {
			return fmt.Errorf(
				"table %q uses incompatible id type %q; migrate it explicitly before applying the modular schema",
				table,
				dataType,
			)
		}
	}
	return nil
}

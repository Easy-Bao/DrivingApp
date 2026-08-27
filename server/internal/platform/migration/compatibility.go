package migration

import (
	"context"
	"errors"
	"fmt"

	"entgo.io/ent/dialect"
	entsql "entgo.io/ent/dialect/sql"
)

func ValidateCompatibleSchema(ctx context.Context, database dialect.ExecQuerier) error {
	for _, table := range []string{
		"users",
		"rides",
		"bid_sessions",
		"reviews",
		"notifications",
	} {
		rows := &entsql.Rows{}
		err := database.Query(ctx, `
			SELECT COALESCE((
				SELECT data_type
				FROM information_schema.columns
				WHERE table_schema = 'public'
				  AND table_name = $1
				  AND column_name = 'id'
			), '')`, []any{table}, rows)
		if err != nil {
			return fmt.Errorf("inspect %s.id: %w", table, err)
		}
		dataType, err := entsql.ScanString(rows)
		closeErr := rows.Close()
		if joinedErr := errors.Join(err, closeErr); joinedErr != nil {
			return fmt.Errorf("inspect %s.id: %w", table, joinedErr)
		}
		if dataType == "" {
			continue
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

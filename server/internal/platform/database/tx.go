package database

import (
	"context"
	"errors"
	"log/slog"

	"github.com/jackc/pgx/v5"
)

// Rollback closes a transaction when the owning operation exits before commit.
// A rollback after a successful commit returns pgx.ErrTxClosed and is expected.
func Rollback(ctx context.Context, transaction pgx.Tx) {
	if transaction == nil {
		return
	}
	if err := transaction.Rollback(ctx); err != nil && !errors.Is(err, pgx.ErrTxClosed) {
		slog.WarnContext(ctx, "rollback transaction failed", "error", err)
	}
}

package database

import (
	"context"
	"errors"
	"log/slog"
	"time"

	"github.com/jackc/pgx/v5"
)

// Rollback closes a transaction when the owning operation exits before commit.
// A rollback after a successful commit returns pgx.ErrTxClosed and is expected.
func Rollback(ctx context.Context, transaction pgx.Tx) {
	if transaction == nil {
		return
	}
	rollbackCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), 5*time.Second)
	defer cancel()
	if err := transaction.Rollback(rollbackCtx); err != nil && !errors.Is(err, pgx.ErrTxClosed) {
		slog.WarnContext(rollbackCtx, "rollback transaction failed", "error", err)
	}
}

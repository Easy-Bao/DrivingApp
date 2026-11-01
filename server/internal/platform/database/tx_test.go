package database

import (
	"context"
	"errors"
	"testing"

	"github.com/jackc/pgx/v5"
)

type mockTx struct {
	pgx.Tx
	rollbackErr       error
	rollbackCtx       context.Context
	errDuringRollback error
}

func (m *mockTx) Rollback(ctx context.Context) error {
	m.rollbackCtx = ctx
	m.errDuringRollback = ctx.Err()
	return m.rollbackErr
}

func TestRollbackHandlesNilInputs(t *testing.T) {
	// Must not panic on nil transaction
	Rollback(context.Background(), nil)
	Rollback(nil, nil)

	// Must not panic on nil context with valid transaction
	tx := &mockTx{}
	Rollback(nil, tx)
	if tx.rollbackCtx == nil {
		t.Fatal("expected non-nil rollback context even when caller passed nil context")
	}
}

func TestRollbackIsolatesCancelledContext(t *testing.T) {
	parentCtx, cancel := context.WithCancel(context.Background())
	cancel()

	tx := &mockTx{}
	Rollback(parentCtx, tx)

	if tx.rollbackCtx == nil {
		t.Fatal("expected rollback to be called on transaction")
	}
	if tx.errDuringRollback != nil {
		t.Fatalf("expected rollback context to be un-cancelled during execution, got err = %v", tx.errDuringRollback)
	}
	deadline, ok := tx.rollbackCtx.Deadline()
	if !ok || deadline.IsZero() {
		t.Fatal("expected rollback context to have a dedicated timeout deadline")
	}
}

func TestRollbackIgnoresErrTxClosed(t *testing.T) {
	tx := &mockTx{rollbackErr: pgx.ErrTxClosed}
	// Should cleanly handle already-closed transaction
	Rollback(context.Background(), tx)
	if tx.rollbackCtx == nil {
		t.Fatal("expected rollback to be executed")
	}
}

func TestRollbackLogsOnUnexpectedError(t *testing.T) {
	unexpectedErr := errors.New("network connection reset")
	tx := &mockTx{rollbackErr: unexpectedErr}
	// Should handle error gracefully without panicking
	Rollback(context.Background(), tx)
	if tx.rollbackCtx == nil {
		t.Fatal("expected rollback to be executed")
	}
}

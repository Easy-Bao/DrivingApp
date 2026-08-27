package main

import (
	"context"
	"errors"
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	platformmigration "github.com/Easy-Bao/DrivingApp/server/internal/platform/migration"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	if err := run(ctx); err != nil {
		slog.Error("migration command failed", "error", err)
		os.Exit(1)
	}
}

func run(ctx context.Context) error {
	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		return errors.New("database url is required")
	}
	connection, err := database.OpenPostgresConnection(databaseURL)
	if err != nil {
		return err
	}
	defer connection.Client.Close()
	if err := platformmigration.NewRunner(connection.Driver).Run(ctx); err != nil {
		return err
	}
	return platformmigration.ValidateEntSchema(ctx, connection.Client)
}

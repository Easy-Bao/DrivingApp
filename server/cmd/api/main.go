package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	"github.com/Easy-Bao/DrivingApp/server/internal/app"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	if err := run(ctx); err != nil {
		slog.Error("api command failed", "error", err)
		os.Exit(1)
	}
}

func run(ctx context.Context) error {
	config, err := app.LoadConfig()
	if err != nil {
		return fmt.Errorf("load application config: %w", err)
	}
	application, err := app.NewApplication(ctx, config)
	if err != nil {
		return fmt.Errorf("create application: %w", err)
	}
	if err := application.Run(ctx); err != nil {
		return fmt.Errorf("run application: %w", err)
	}
	return nil
}

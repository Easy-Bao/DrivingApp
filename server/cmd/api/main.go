package main

import (
	"context"
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
		return err
	}
	application, err := app.NewApplication(ctx, config)
	if err != nil {
		return err
	}
	return application.Run(ctx)
}

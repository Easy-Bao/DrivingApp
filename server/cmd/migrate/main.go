package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"

	platformmigration "github.com/Easy-Bao/DrivingApp/server/internal/platform/migration"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/database"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	url := os.Getenv("DATABASE_URL")
	if url == "" {
		log.Fatal("DATABASE_URL is required")
	}
	connection, err := database.OpenPostgresConnection(url)
	if err != nil {
		log.Fatal(err)
	}
	defer connection.Client.Close()
	if err := platformmigration.NewRunner(connection.Driver).Run(ctx); err != nil {
		log.Fatal(err)
	}
	if err := platformmigration.ValidateEntSchema(ctx, connection.Client); err != nil {
		log.Fatal(err)
	}
}

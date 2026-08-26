package main

import (
	"context"
	"database/sql"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	platformmigration "github.com/Easy-Bao/DrivingApp/server/internal/platform/migration"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/database"
	_ "github.com/lib/pq"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	url := os.Getenv("DATABASE_URL")
	if url == "" {
		log.Fatal("DATABASE_URL is required")
	}
	url = database.NormalizePostgresURL(url)
	client, err := ent.Open("postgres", url)
	if err != nil {
		log.Fatal(err)
	}
	defer client.Close()
	database, err := sql.Open("postgres", url)
	if err != nil {
		log.Fatal(err)
	}
	defer database.Close()
	if err := platformmigration.NewRunner(database, client).Run(ctx); err != nil {
		log.Fatal(err)
	}
	if err := platformmigration.ValidateEntSchema(ctx, client); err != nil {
		log.Fatal(err)
	}
}

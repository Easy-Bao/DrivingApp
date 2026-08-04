package main

import (
	"context"
	"database/sql"
	"log"
	"os"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/ent/migrate"
	platformmigration "github.com/Easy-Bao/DrivingApp/server/internal/platform/migration"
	_ "github.com/lib/pq"
)

func main() {
	url := os.Getenv("DATABASE_URL")
	if url == "" {
		log.Fatal("DATABASE_URL is required")
	}
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
	if err := platformmigration.PreserveLegacyTables(context.Background(), database); err != nil {
		log.Fatal(err)
	}
	if err := client.Schema.Create(context.Background(), migrate.WithForeignKeys(true)); err != nil {
		log.Fatal(err)
	}
}

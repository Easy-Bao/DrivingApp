package main

import (
	"context"
	"log"
	"os"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/ent/migrate"
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
	if err := client.Schema.Create(context.Background(), migrate.WithForeignKeys(true)); err != nil {
		log.Fatal(err)
	}
}

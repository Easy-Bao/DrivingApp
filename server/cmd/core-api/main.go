package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/ent/migrate"
	"github.com/Easy-Bao/DrivingApp/server/internal/coreapi"
	"github.com/Easy-Bao/DrivingApp/server/internal/location/adapter/mapbox"
	locationhttp "github.com/Easy-Bao/DrivingApp/server/internal/location/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/location/usecase"
	_ "github.com/lib/pq"
)

func main() {
	router := http.NewServeMux()
	coreHandler := coreapi.NewHandler(os.Getenv("JWT_SECRET"))
	if databaseURL := os.Getenv("DATABASE_URL"); databaseURL != "" {
		client, err := ent.Open("postgres", databaseURL)
		if err != nil {
			log.Fatal(err)
		}
		if err := client.Schema.Create(context.Background(), migrate.WithForeignKeys(true)); err != nil {
			log.Fatal(err)
		}
		defer client.Close()
		coreHandler = coreapi.NewPersistentHandler(client, os.Getenv("JWT_SECRET"))
	}
	router.Handle("/", coreHandler)
	provider := mapbox.NewProvider(os.Getenv("MAPBOX_ACCESS_TOKEN"))
	locationhttp.NewHandler(usecase.NewService(provider)).RegisterRoutes(router)
	router.HandleFunc("GET /health", func(writer http.ResponseWriter, _ *http.Request) {
		writer.Header().Set("Content-Type", "application/json")
		_, _ = writer.Write([]byte(`{"status":"ok","service":"core-api"}`))
	})

	server := &http.Server{
		Addr:              ":" + port("CORE_API_PORT", "8080"),
		Handler:           router,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	log.Printf("core-api listening on %s", server.Addr)
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatal(err)
	}
}

func port(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}

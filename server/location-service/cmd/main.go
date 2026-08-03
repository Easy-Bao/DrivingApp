package main

import (
	"fmt"
	"location-service/internal/adapter/mapbox"
	"location-service/internal/adapter/queue"
	"location-service/internal/adapter/redis"
	httptransport "location-service/internal/transport/http"
	wstransport "location-service/internal/transport/ws"
	"location-service/internal/usecase"
	"log"
	"net/http"
	"os"
	"time"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8089"
	}

	redisURL := os.Getenv("REDIS_URL")
	amqpURL := os.Getenv("RABBITMQ_URL")
	mapboxToken := os.Getenv("MAPBOX_ACCESS_TOKEN")
	if mapboxToken == "" {
		mapboxToken = os.Getenv("MAPBOX_PUBLIC_TOKEN")
	}

	mapboxAdapter := mapbox.NewMapboxAdapter(mapboxToken)
	redisAdapter := redis.NewRedisAdapter(redisURL)
	queueAdapter := queue.NewRabbitMQAdapter(amqpURL)

	locationUseCase := usecase.NewLocationUseCase(
		mapboxAdapter,
		redisAdapter,
		queueAdapter,
	)

	router := http.NewServeMux()

	httpHandler := httptransport.NewHTTPHandler(locationUseCase)
	httpHandler.RegisterRoutes(router)

	wsHandler := wstransport.NewWSHandler(locationUseCase)
	wsHandler.RegisterRoutes(router)

	router.HandleFunc("GET /health", func(writer http.ResponseWriter, request *http.Request) {
		writer.Header().Set("Content-Type", "application/json")
		_, _ = writer.Write([]byte(`{"status":"Location Service OK"}`))
	})

	log.Printf("Starting Location Service on port %s...", port)
	server := &http.Server{
		Addr:              fmt.Sprintf(":%s", port),
		Handler:           router,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatalf("Failed to run server: %v", err)
	}
}

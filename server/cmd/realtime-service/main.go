package main

import (
	"log"
	"net/http"
	"os"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	geo "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/adapter"
	geows "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/transport/ws"
	geousecase "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/ws"
	redis "github.com/redis/go-redis/v9"
)

func main() {
	router := http.NewServeMux()
	redisURL := os.Getenv("REDIS_URL")
	if redisURL == "" {
		log.Fatal("REDIS_URL is required")
	}
	redisOptions, err := redis.ParseURL(redisURL)
	if err != nil {
		log.Fatal(err)
	}
	redisClient := redis.NewClient(redisOptions)
	geoService := geousecase.NewService(geo.NewRedisRepository(redisClient))
	router.Handle("/ws", ws.NewHandlerWithSink(ws.NewHub(), token.NewVerifier(os.Getenv("JWT_SECRET")), geows.NewEventHandler(geoService)))
	router.HandleFunc("GET /health", func(writer http.ResponseWriter, _ *http.Request) {
		writer.Header().Set("Content-Type", "application/json")
		_, _ = writer.Write([]byte(`{"status":"ok","service":"realtime-service"}`))
	})

	log.Println("realtime-service listening on :8081")
	if err := http.ListenAndServe(":8081", router); err != nil {
		log.Fatal(err)
	}
}

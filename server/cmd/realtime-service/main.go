package main

import (
	"log"
	"net/http"
	"os"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	chatadapter "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/adapter"
	chatws "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/transport/ws"
	chatusecase "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/usecase"
	geo "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/adapter"
	geoh "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/transport/http"
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
	chatService := chatusecase.NewService(chatadapter.NewHub())
	events := ws.NewEventRouter()
	events.Register("LOCATION_UPDATE", geows.NewEventHandler(geoService))
	events.Register("CHAT_MESSAGE", chatws.NewEventHandler(chatService))
	router.Handle("/ws", ws.NewHandlerWithSink(ws.NewHub(), token.NewVerifier(os.Getenv("JWT_SECRET")), events))
	geoh.NewRouter(geoService).RegisterRoutes(router)
	router.HandleFunc("GET /health", func(writer http.ResponseWriter, _ *http.Request) {
		writer.Header().Set("Content-Type", "application/json")
		_, _ = writer.Write([]byte(`{"status":"ok","service":"realtime-service"}`))
	})

	log.Println("realtime-service listening on :8081")
	if err := http.ListenAndServe(":8081", router); err != nil {
		log.Fatal(err)
	}
}

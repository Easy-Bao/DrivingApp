package main

import (
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	chatadapter "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/adapter"
	chath "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/transport/http"
	chatws "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/transport/ws"
	chatusecase "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/usecase"
	geo "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/adapter"
	geoh "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/transport/http"
	geows "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/transport/ws"
	geousecase "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/ws"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/api"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/database"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/logger"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/middleware"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/security"
	"github.com/go-chi/chi/v5"
)

func main() {
	router := chi.NewRouter()
	redisURL := os.Getenv("REDIS_URL")
	if redisURL == "" {
		log.Fatal("REDIS_URL is required")
	}
	redisClient, err := database.OpenRedis(redisURL)
	if err != nil {
		log.Fatal(err)
	}
	defer redisClient.Close()
	tokenManager := security.NewTokenManager(requiredJWTSecret())
	geoService := geousecase.NewService(geo.NewRedisRepository(redisClient))
	chatHistory := chatadapter.NewRedisRepository(redisClient)
	chatService := chatusecase.NewService(chatadapter.NewHub(), chatHistory)
	events := ws.NewEventRouter()
	events.Register("LOCATION_UPDATE", geows.NewEventHandler(geoService))
	events.Register("CHAT_MESSAGE", chatws.NewEventHandler(chatService))
	router.Handle(api.V1Prefix+"/chat/ws", ws.NewHandlerWithSink(ws.NewHub(), tokenManager, events))
	geoh.NewRouter(geoService, tokenManager).RegisterRoutes(router)
	chath.NewRouter(chatService).RegisterRoutes(router)
	router.Get("/health", func(writer http.ResponseWriter, _ *http.Request) {
		writer.Header().Set("Content-Type", "application/json")
		_, _ = writer.Write([]byte(`{"status":"ok","service":"realtime-service"}`))
	})

	address := ":" + port("REALTIME_SERVICE_PORT", "8081")
	log.Println("realtime-service listening on " + address)
	if err := http.ListenAndServe(address, middleware.Logging(logger.New("realtime-service"))(
		middleware.SecureHTTPWithIdempotency(
			router,
			middleware.SecurityConfigFromEnv(),
			middleware.NewRateLimiterFromEnv(middleware.NewRedisCounterStore(redisClient)),
			middleware.NewIdempotency(middleware.NewRedisIdempotencyStore(redisClient), 10*time.Minute),
		),
	)); err != nil {
		log.Fatal(err)
	}
}

func port(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}

func requiredJWTSecret() string {
	secret := strings.TrimSpace(os.Getenv("JWT_SECRET"))
	if err := security.ValidateTokenSecret(secret); err != nil {
		log.Fatal(err)
	}
	return secret
}

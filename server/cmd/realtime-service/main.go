package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	chatadapter "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/adapter"
	chath "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/transport/http"
	chatws "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/transport/ws"
	chatusecase "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/usecase"
	eventadapter "github.com/Easy-Bao/DrivingApp/server/internal/realtime/event/adapter"
	geo "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/adapter"
	geoh "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/transport/http"
	geows "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/transport/ws"
	geousecase "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/stream"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/ws"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/api"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/database"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/logger"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/middleware"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/security"
	"github.com/go-chi/chi/v5"
)

func main() {
	runContext, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

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
	geoService := geousecase.NewService(
		geo.NewRedisRepository(redisClient),
		geousecase.WithRideAssignments(eventadapter.NewRedisRideAssignmentLookup(redisClient)),
		geousecase.WithEventPublisher(eventadapter.NewRedisPublisher(redisClient)),
	)
	chatHistory := chatadapter.NewRedisRepository(redisClient)
	chatService := chatusecase.NewService(chatadapter.NewHub(), chatHistory)
	eventHub := stream.NewHub()
	eventSubscriber := eventadapter.NewRedisSubscriber(redisClient)
	go func() {
		if runErr := eventSubscriber.Run(runContext, eventHub); runErr != nil && runContext.Err() == nil {
			log.Printf("realtime event subscriber stopped: %v", runErr)
		}
	}()
	events := ws.NewEventRouter()
	events.Register("LOCATION_UPDATE", geows.NewEventHandler(geoService))
	events.Register("CHAT_MESSAGE", chatws.NewEventHandler(chatService))
	router.Handle(api.V1Prefix+"/chat/ws", ws.NewHandlerWithSink(ws.NewHub(), tokenManager, events, chatService))
	securityConfig := middleware.SecurityConfigFromEnv()
	router.Handle(api.V1Prefix+"/realtime/ws", stream.NewHandler(eventHub, tokenManager, securityConfig.AllowedOrigins))
	geoh.NewRouter(geoService, tokenManager).RegisterRoutes(router)
	chath.NewRouter(chatService, tokenManager).RegisterRoutes(router)
	router.Get("/health", func(writer http.ResponseWriter, _ *http.Request) {
		writer.Header().Set("Content-Type", "application/json")
		_, _ = writer.Write([]byte(`{"status":"ok","service":"realtime-service"}`))
	})

	address := ":" + port("REALTIME_SERVICE_PORT", "8081")
	log.Println("realtime-service listening on " + address)
	server := &http.Server{
		Addr: address,
		Handler: middleware.Logging(logger.New("realtime-service"))(
			middleware.SecureHTTPWithIdempotency(
				router,
				securityConfig,
				middleware.NewRateLimiterFromEnv(middleware.NewRedisCounterStore(redisClient)),
				middleware.NewIdempotency(middleware.NewRedisIdempotencyStore(redisClient), 10*time.Minute),
			)),
		ReadHeaderTimeout: 5 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	server.RegisterOnShutdown(eventHub.Close)
	serverErrors := make(chan error, 1)
	go func() {
		serverErrors <- server.ListenAndServe()
	}()

	select {
	case serverErr := <-serverErrors:
		if serverErr != nil && !errors.Is(serverErr, http.ErrServerClosed) {
			log.Fatal(serverErr)
		}
	case <-runContext.Done():
		shutdownContext, cancel := context.WithTimeout(context.Background(), 15*time.Second)
		defer cancel()
		if shutdownErr := server.Shutdown(shutdownContext); shutdownErr != nil {
			log.Printf("realtime-service shutdown failed: %v", shutdownErr)
		}
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

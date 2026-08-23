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

	adminpostgres "github.com/Easy-Bao/DrivingApp/server/internal/admin/adapter/postgres"
	adminhttp "github.com/Easy-Bao/DrivingApp/server/internal/admin/transport/http"
	adminusecase "github.com/Easy-Bao/DrivingApp/server/internal/admin/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/email"
	authpostgres "github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/postgres"
	authredis "github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/redis"
	authhttp "github.com/Easy-Bao/DrivingApp/server/internal/auth/transport/http"
	authusecase "github.com/Easy-Bao/DrivingApp/server/internal/auth/usecase"
	documentpostgres "github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/adapter/postgres"
	documentstorage "github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/adapter/storage"
	documenthttp "github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/transport/http"
	documentusecase "github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/location/adapter/mapbox"
	locationqueue "github.com/Easy-Bao/DrivingApp/server/internal/location/adapter/queue"
	locationredis "github.com/Easy-Bao/DrivingApp/server/internal/location/adapter/redis"
	locationdomain "github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
	locationhttp "github.com/Easy-Bao/DrivingApp/server/internal/location/transport/http"
	locationusecase "github.com/Easy-Bao/DrivingApp/server/internal/location/usecase"
	passengerhome "github.com/Easy-Bao/DrivingApp/server/internal/passenger/home"
	passengerhomeadapter "github.com/Easy-Bao/DrivingApp/server/internal/passenger/home/adapter"
	passengerhomehttp "github.com/Easy-Bao/DrivingApp/server/internal/passenger/home/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/assignment"
	assignmentadapter "github.com/Easy-Bao/DrivingApp/server/internal/realtime/assignment/adapter"
	chatadapter "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/adapter"
	chath "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/transport/http"
	chatws "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/transport/ws"
	chatusecase "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/usecase"
	eventadapter "github.com/Easy-Bao/DrivingApp/server/internal/realtime/event/adapter"
	geo "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/adapter"
	geoh "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/transport/http"
	geousecase "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/stream"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/ws"
	ridespostgres "github.com/Easy-Bao/DrivingApp/server/internal/rides/adapter/postgres"
	rideshttp "github.com/Easy-Bao/DrivingApp/server/internal/rides/transport/http"
	ridesusecase "github.com/Easy-Bao/DrivingApp/server/internal/rides/usecase"
	userspostgres "github.com/Easy-Bao/DrivingApp/server/internal/users/adapter/postgres"
	usershttp "github.com/Easy-Bao/DrivingApp/server/internal/users/transport/http"
	usersusecase "github.com/Easy-Bao/DrivingApp/server/internal/users/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/api"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/database"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/logger"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/middleware"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/security"
	"github.com/go-chi/chi/v5"
)

const apiServiceName = "api"

func main() {
	runContext, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	router := chi.NewRouter()
	jwtSecret := requiredJWTSecret()
	verifier := security.NewTokenManager(jwtSecret)
	securityConfig := middleware.SecurityConfigFromEnv()
	proxyTrust, err := middleware.NewProxyTrust(os.Getenv("TRUSTED_PROXY_CIDRS"))
	if err != nil {
		log.Fatal(err)
	}
	adminAuthorizer := security.NewAdminAuthorizer(os.Getenv("ADMIN_USER_IDS"))

	pricingConfig, err := ridesusecase.LoadPricingConfig()
	if err != nil {
		log.Fatal(err)
	}

	databaseURL := strings.TrimSpace(os.Getenv("DATABASE_URL"))
	if databaseURL == "" {
		log.Fatal("DATABASE_URL is required")
	}
	databaseClient, err := database.OpenPostgres(databaseURL)
	if err != nil {
		log.Fatal(err)
	}
	defer databaseClient.Close()

	redisURL := strings.TrimSpace(os.Getenv("REDIS_URL"))
	if redisURL == "" {
		log.Fatal("REDIS_URL is required")
	}
	redisClient, err := database.OpenRedis(redisURL)
	if err != nil {
		log.Fatal(err)
	}
	defer redisClient.Close()

	authRepository := authpostgres.NewUserRepository(databaseClient)
	registerService := authusecase.NewRegisterService(authRepository, verifier)
	authenticateService := authusecase.NewAuthenticateService(authRepository, verifier)

	authRouter := authhttp.NewRouter(registerService, authenticateService, authusecase.NewOTPServiceWithPending(
		authRepository,
		authredis.NewOTPStore(redisClient),
		email.NewGoMailGatewayFromEnv(),
		verifier,
		authredis.NewPendingRegistrationStore(redisClient),
		registerService,
	))
	usersRouter := usershttp.NewRouter(usersusecase.NewService(userspostgres.NewProfileRepository(databaseClient)), verifier)
	documentRepository := documentpostgres.NewRepository(databaseClient)
	documentRouter := documenthttp.NewRouter(
		documentusecase.NewService(documentRepository, documentstorage.NewRedisStorage(redisClient)),
		verifier,
		adminAuthorizer,
	)
	ridesRepository := ridespostgres.NewRepository(databaseClient, pricingConfig.PlatformCommissionBPS)
	mapboxProvider := mapbox.NewProvider(os.Getenv("MAPBOX_ACCESS_TOKEN"))
	routeCalculator := ridesusecase.RouteCalculatorFunc(func(ctx context.Context, originLat, originLng, destinationLat, destinationLng float64) (ridesusecase.RouteMetrics, error) {
		route, err := mapboxProvider.Route(ctx, locationdomain.Coordinates{Latitude: originLat, Longitude: originLng}, locationdomain.Coordinates{Latitude: destinationLat, Longitude: destinationLng}, locationdomain.RouteOptions{})
		if err != nil {
			return ridesusecase.RouteMetrics{}, err
		}
		return ridesusecase.RouteMetrics{DistanceKm: route.DistanceKm, DurationMinutes: route.DurationMin}, nil
	})
	ridesService := ridesusecase.NewServiceWithRouteCalculator(
		ridesRepository,
		routeCalculator,
		pricingConfig,
		eventadapter.NewRedisPublisher(redisClient),
	)
	rideAssignments := assignment.NewResolver(
		eventadapter.NewRedisRideAssignmentLookup(redisClient),
		assignmentadapter.NewRideRepositoryLookup(ridesRepository),
	)
	ridesRouter := rideshttp.NewRouter(ridesService, verifier)
	adminRouter := adminhttp.NewRouter(adminusecase.NewService(adminpostgres.NewRepository(databaseClient)), verifier, adminAuthorizer)
	geoService := geousecase.NewService(
		geo.NewRedisRepository(redisClient),
		geousecase.WithRideAssignments(rideAssignments),
		geousecase.WithEventPublisher(eventadapter.NewRedisPublisher(redisClient)),
	)

	var locationPublisher locationdomain.EventPublisher
	if rabbitURL := strings.TrimSpace(os.Getenv("RABBITMQ_URL")); rabbitURL != "" {
		queuePublisher, publishErr := locationqueue.NewPublisher(rabbitURL)
		if publishErr != nil {
			log.Printf("location event publisher disabled: %v", publishErr)
		} else {
			locationPublisher = queuePublisher
			defer queuePublisher.Close()
		}
	}
	locationService := locationusecase.NewServiceWithInfrastructure(
		mapboxProvider,
		locationredis.NewCache(redisClient),
		locationPublisher,
	)

	authRouter.RegisterRoutes(router)
	usersRouter.RegisterRoutes(router)
	documentRouter.RegisterRoutes(router)
	ridesRouter.RegisterRoutes(router)
	adminRouter.RegisterRoutes(router)
	locationhttp.NewRouter(locationService).RegisterRoutes(router)
	passengerHomeQuery := passengerhome.NewService(
		passengerhomeadapter.NewRidesReader(ridesService),
		passengerhomeadapter.NewLocationResolver(locationService),
	)
	passengerhomehttp.NewRouter(passengerHomeQuery, verifier).RegisterRoutes(router)

	chatHistory := chatadapter.NewRedisRepository(redisClient)
	chatService := chatusecase.NewService(chatadapter.NewHub(), chatHistory).
		WithEventPublisher(eventadapter.NewRedisPublisher(redisClient)).
		WithRideAssignmentLookup(rideAssignments)
	eventHub := stream.NewHub()
	eventSubscriber := eventadapter.NewRedisSubscriber(redisClient)
	go func() {
		if runErr := eventSubscriber.Run(runContext, eventHub); runErr != nil && runContext.Err() == nil {
			log.Printf("realtime event subscriber stopped: %v", runErr)
		}
	}()

	events := ws.NewEventRouter()
	chatEventHandler := chatws.NewEventHandler(chatService)
	events.Register("CHAT_MESSAGE", chatEventHandler)
	events.Register("message", chatEventHandler)
	router.Handle(
		api.V1Prefix+"/chat/ws",
		ws.NewHandlerWithSink(ws.NewHub(), verifier, events, chatService).
			WithAllowedOrigins(securityConfig.AllowedOrigins),
	)
	router.Handle(api.V1Prefix+"/realtime/ws", stream.NewHandler(eventHub, verifier, securityConfig.AllowedOrigins))
	geoh.NewRouter(geoService, verifier).RegisterRoutes(router)
	chath.NewRouter(chatService, verifier).RegisterRoutes(router)

	router.Get("/health", func(writer http.ResponseWriter, _ *http.Request) {
		writer.Header().Set("Content-Type", "application/json")
		_, _ = writer.Write([]byte(`{"status":"ok","service":"api"}`))
	})

	handler := proxyTrust.Middleware(
		middleware.Logging(logger.New(apiServiceName))(
			middleware.SecureHTTPWithIdempotency(
				router,
				securityConfig,
				middleware.NewRateLimiterFromEnv(middleware.NewRedisCounterStore(redisClient)),
				middleware.NewIdempotency(middleware.NewRedisIdempotencyStore(redisClient), 10*time.Minute),
			),
		),
	)
	server := &http.Server{
		Addr:              ":" + apiPort(),
		Handler:           handler,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	server.RegisterOnShutdown(eventHub.Close)
	log.Printf("%s listening on %s", apiServiceName, server.Addr)

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
			log.Printf("api shutdown failed: %v", shutdownErr)
		}
	}
}

func apiPort() string {
	if value := strings.TrimSpace(os.Getenv("API_PORT")); value != "" {
		return value
	}
	if value := strings.TrimSpace(os.Getenv("GATEWAY_PORT")); value != "" {
		return value
	}
	return "8000"
}

func requiredJWTSecret() string {
	secret := strings.TrimSpace(os.Getenv("JWT_SECRET"))
	if err := security.ValidateTokenSecret(secret); err != nil {
		log.Fatal(err)
	}
	return secret
}

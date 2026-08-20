package main

import (
	"context"
	"database/sql"
	"errors"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/ent/migrate"
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
	platformmigration "github.com/Easy-Bao/DrivingApp/server/internal/platform/migration"
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
	_ "github.com/lib/pq"
)

const apiServiceName = "api"

func main() {
	runContext, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	router := chi.NewRouter()
	jwtSecret := requiredJWTSecret()
	verifier := security.NewTokenManager(jwtSecret)
	securityConfig := middleware.SecurityConfigFromEnv()
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

	databaseConnection, err := sql.Open("postgres", database.NormalizePostgresURL(databaseURL))
	if err != nil {
		log.Fatal(err)
	}
	defer databaseConnection.Close()
	if err := platformmigration.PreserveLegacyTables(context.Background(), databaseConnection); err != nil {
		log.Fatal(err)
	}
	if err := databaseClient.Schema.Create(context.Background(), migrate.WithForeignKeys(true)); err != nil {
		log.Fatal(err)
	}

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
	registerService := authusecase.NewRegisterService(authRepository, verifier, authRepository)
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
	ridesRouter := rideshttp.NewRouter(ridesService, verifier)
	adminRouter := adminhttp.NewRouter(adminusecase.NewService(adminpostgres.NewRepository(databaseClient)), verifier, adminAuthorizer)
	geoService := geousecase.NewService(
		geo.NewRedisRepository(redisClient),
		geousecase.WithRideAssignments(eventadapter.NewRedisRideAssignmentLookup(redisClient)),
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
		WithRideAssignmentLookup(eventadapter.NewRedisRideAssignmentLookup(redisClient))
	eventHub := stream.NewHub()
	eventSubscriber := eventadapter.NewRedisSubscriber(redisClient)
	go func() {
		if runErr := eventSubscriber.Run(runContext, eventHub); runErr != nil && runContext.Err() == nil {
			log.Printf("realtime event subscriber stopped: %v", runErr)
		}
	}()

	events := ws.NewEventRouter()
	events.Register("LOCATION_UPDATE", geows.NewEventHandler(geoService))
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

	handler := sanitizeForwardedHeaders(
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

// sanitizeForwardedHeaders prevents a direct client from spoofing the values
// used for rate limiting and transport security. A trusted reverse proxy can
// be configured separately through the deployment boundary.
func sanitizeForwardedHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		request.Header.Del("X-Forwarded-For")
		request.Header.Del("X-Forwarded-Host")
		request.Header.Del("X-Forwarded-Port")
		request.Header.Del("X-Forwarded-Proto")
		request.Header.Set("X-Forwarded-For", remoteHost(request.RemoteAddr))
		if request.TLS != nil {
			request.Header.Set("X-Forwarded-Proto", "https")
		} else {
			request.Header.Set("X-Forwarded-Proto", "http")
		}
		next.ServeHTTP(writer, request)
	})
}

func remoteHost(remoteAddr string) string {
	host, _, err := net.SplitHostPort(strings.TrimSpace(remoteAddr))
	if err == nil && host != "" {
		return host
	}
	return strings.TrimSpace(remoteAddr)
}

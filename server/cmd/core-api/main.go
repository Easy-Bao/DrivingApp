package main

import (
	"context"
	"database/sql"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/ent/migrate"
	adminpostgres "github.com/Easy-Bao/DrivingApp/server/internal/admin/adapter/postgres"
	adminhttp "github.com/Easy-Bao/DrivingApp/server/internal/admin/transport/http"
	adminusecase "github.com/Easy-Bao/DrivingApp/server/internal/admin/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/email"
	authpostgres "github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/postgres"
	authredis "github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/redis"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	authhttp "github.com/Easy-Bao/DrivingApp/server/internal/auth/transport/http"
	authusecase "github.com/Easy-Bao/DrivingApp/server/internal/auth/usecase"
	documentpostgres "github.com/Easy-Bao/DrivingApp/server/internal/driver_doc/adapter/postgres"
	documentstorage "github.com/Easy-Bao/DrivingApp/server/internal/driver_doc/adapter/storage"
	documenthttp "github.com/Easy-Bao/DrivingApp/server/internal/driver_doc/transport/http"
	documentusecase "github.com/Easy-Bao/DrivingApp/server/internal/driver_doc/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/location/adapter/mapbox"
	locationqueue "github.com/Easy-Bao/DrivingApp/server/internal/location/adapter/queue"
	locationredis "github.com/Easy-Bao/DrivingApp/server/internal/location/adapter/redis"
	locationdomain "github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
	locationhttp "github.com/Easy-Bao/DrivingApp/server/internal/location/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/location/usecase"
	platformmigration "github.com/Easy-Bao/DrivingApp/server/internal/platform/migration"
	ridespostgres "github.com/Easy-Bao/DrivingApp/server/internal/rides/adapter/postgres"
	rideshttp "github.com/Easy-Bao/DrivingApp/server/internal/rides/transport/http"
	ridesusecase "github.com/Easy-Bao/DrivingApp/server/internal/rides/usecase"
	userspostgres "github.com/Easy-Bao/DrivingApp/server/internal/users/adapter/postgres"
	usershttp "github.com/Easy-Bao/DrivingApp/server/internal/users/transport/http"
	usersusecase "github.com/Easy-Bao/DrivingApp/server/internal/users/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/database"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/logger"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/middleware"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/security"
	"github.com/go-chi/chi/v5"
	_ "github.com/lib/pq"
	redisclient "github.com/redis/go-redis/v9"
)

func main() {
	router := chi.NewRouter()
	var authRouter *authhttp.Router
	var usersRouter *usershttp.Router
	var documentRouter *documenthttp.Router
	var ridesRouter *rideshttp.Router
	var adminRouter *adminhttp.Router
	var documentRepository *documentpostgres.Repository
	var registerService *authusecase.RegisterService
	var authenticateService *authusecase.AuthenticateService
	var verifier *security.TokenManager
	var authRepository *authpostgres.UserRepository
	provider := mapbox.NewProvider(os.Getenv("MAPBOX_ACCESS_TOKEN"))
	routeCalculator := ridesusecase.RouteCalculatorFunc(func(ctx context.Context, originLat, originLng, destinationLat, destinationLng float64) (ridesusecase.RouteMetrics, error) {
		route, err := provider.Route(ctx, locationdomain.Coordinates{Latitude: originLat, Longitude: originLng}, locationdomain.Coordinates{Latitude: destinationLat, Longitude: destinationLng})
		if err != nil {
			return ridesusecase.RouteMetrics{}, err
		}
		return ridesusecase.RouteMetrics{DistanceKm: route.DistanceKm, DurationMinutes: route.DurationMin}, nil
	})
	if databaseURL := os.Getenv("DATABASE_URL"); databaseURL != "" {
		client, err := database.OpenPostgres(databaseURL)
		if err != nil {
			log.Fatal(err)
		}
		databaseConnection, err := sql.Open("postgres", database.NormalizePostgresURL(databaseURL))
		if err != nil {
			log.Fatal(err)
		}
		if err := platformmigration.PreserveLegacyTables(context.Background(), databaseConnection); err != nil {
			log.Fatal(err)
		}
		defer databaseConnection.Close()
		if err := client.Schema.Create(context.Background(), migrate.WithForeignKeys(true)); err != nil {
			log.Fatal(err)
		}
		defer client.Close()
		authRepository = authpostgres.NewUserRepository(client)
		tokenManager := token.NewIssuer(os.Getenv("JWT_SECRET"))
		registerService = authusecase.NewRegisterService(authRepository, tokenManager, authRepository)
		authenticateService = authusecase.NewAuthenticateService(authRepository, tokenManager)
		verifier = token.NewVerifier(os.Getenv("JWT_SECRET"))
		usersRouter = usershttp.NewRouter(usersusecase.NewService(userspostgres.NewProfileRepository(client)), verifier)
		documentRepository = documentpostgres.NewRepository(client)
		ridesRouter = rideshttp.NewRouter(ridesusecase.NewServiceWithRouteCalculator(ridespostgres.NewRepository(client), routeCalculator), verifier)
		adminRouter = adminhttp.NewRouter(adminusecase.NewService(adminpostgres.NewRepository(client)), verifier)
	} else {
		log.Fatal("DATABASE_URL is required")
	}
	var cache locationdomain.Cache
	var publisher locationdomain.EventPublisher
	var redisClient *redisclient.Client
	if redisURL := os.Getenv("REDIS_URL"); redisURL != "" {
		var err error
		redisClient, err = database.OpenRedis(redisURL)
		if err != nil {
			log.Fatal(err)
		}
		cache = locationredis.NewCache(redisClient)
	} else {
		log.Fatal("REDIS_URL is required")
	}
	if registerService != nil && authenticateService != nil && verifier != nil {
		var otpService *authusecase.OTPService
		if redisClient != nil && authRepository != nil {
			otpService = authusecase.NewOTPServiceWithPending(
				authRepository,
				authredis.NewOTPStore(redisClient),
				email.NewGoMailGatewayFromEnv(),
				verifier,
				authredis.NewPendingRegistrationStore(redisClient),
				registerService,
			)
		}
		authRouter = authhttp.NewRouter(registerService, authenticateService, otpService)
	}
	if documentRepository != nil && redisClient != nil && verifier != nil {
		documentRouter = documenthttp.NewRouter(documentusecase.NewService(documentRepository, documentstorage.NewRedisStorage(redisClient)), verifier)
	}
	if authRouter != nil {
		authRouter.RegisterRoutes(router)
	}
	if usersRouter != nil {
		usersRouter.RegisterRoutes(router)
	}
	if documentRouter != nil {
		documentRouter.RegisterRoutes(router)
	}
	if ridesRouter != nil {
		ridesRouter.RegisterRoutes(router)
	}
	if adminRouter != nil {
		adminRouter.RegisterRoutes(router)
	}
	if rabbitURL := os.Getenv("RABBITMQ_URL"); rabbitURL != "" {
		queuePublisher, err := locationqueue.NewPublisher(rabbitURL)
		if err != nil {
			log.Printf("location event publisher disabled: %v", err)
		} else {
			publisher = queuePublisher
			defer queuePublisher.Close()
		}
	}
	if redisClient != nil {
		defer redisClient.Close()
	}
	locationhttp.NewRouter(usecase.NewServiceWithInfrastructure(provider, cache, publisher)).RegisterRoutes(router)
	router.Get("/health", func(writer http.ResponseWriter, _ *http.Request) {
		writer.Header().Set("Content-Type", "application/json")
		_, _ = writer.Write([]byte(`{"status":"ok","service":"core-api"}`))
	})

	server := &http.Server{
		Addr: ":" + port("CORE_API_PORT", "8080"),
		Handler: middleware.Logging(logger.New("core-api"))(
			middleware.SecureHTTPWithIdempotency(
				router,
				middleware.SecurityConfigFromEnv(),
				middleware.NewRateLimiterFromEnv(middleware.NewRedisCounterStore(redisClient)),
				middleware.NewIdempotency(middleware.NewRedisIdempotencyStore(redisClient), 10*time.Minute),
			),
		),
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

package app

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"time"

	adminpostgres "github.com/Easy-Bao/DrivingApp/server/internal/admin/adapter/postgres"
	authpostgres "github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/postgres"
	documents "github.com/Easy-Bao/DrivingApp/server/internal/driver/documents"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	eventadapter "github.com/Easy-Bao/DrivingApp/server/internal/platform/events/adapter"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/logger"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	redisplatform "github.com/Easy-Bao/DrivingApp/server/internal/platform/redis"
	miniostorage "github.com/Easy-Bao/DrivingApp/server/internal/platform/storage/minio"
	websockethub "github.com/Easy-Bao/DrivingApp/server/internal/platform/websocket"
	ridepostgres "github.com/Easy-Bao/DrivingApp/server/internal/ride/adapter/postgres"
	userpostgres "github.com/Easy-Bao/DrivingApp/server/internal/user/adapter/postgres"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Application struct {
	server          *http.Server
	postgresPool    *pgxpool.Pool
	redisClient     redisClient
	eventHub        *websockethub.Hub
	eventSubscriber *eventadapter.RedisEventSubscriber
	logger          *slog.Logger
}

type redisClient interface {
	Close() error
}

func NewApplication(ctx context.Context, config Config) (*Application, error) {
	if ctx == nil {
		ctx = context.Background()
	}
	proxyTrust, err := middleware.NewProxyTrust(config.TrustedProxyCIDRs)
	if err != nil {
		return nil, fmt.Errorf("create proxy trust middleware: %w", err)
	}

	postgresPool, err := database.OpenPostgresPoolWithContext(
		ctx,
		config.DatabaseURL,
		config.PostgresPool,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize postgresql pool: %w", err)
	}
	closePostgresPool := true
	defer func() {
		if closePostgresPool {
			postgresPool.Close()
		}
	}()

	redisClient, err := redisplatform.OpenWithContext(ctx, config.RedisURL)
	if err != nil {
		return nil, fmt.Errorf("open redis client: %w", err)
	}
	closeRedis := true
	defer func() {
		if closeRedis {
			if err := redisClient.Close(); err != nil {
				slog.Warn("close redis client after application setup failure", "error", err)
			}
		}
	}()

	applicationLogger := logger.New(_serviceName, config.LogLevel)
	authStore, err := authpostgres.NewUserStore(postgresPool)
	if err != nil {
		return nil, fmt.Errorf("create auth user store: %w", err)
	}
	sessionStore, err := authpostgres.NewSessionStore(postgresPool)
	if err != nil {
		return nil, fmt.Errorf("create auth session store: %w", err)
	}
	statsReader, err := adminpostgres.NewStatsReader(postgresPool)
	if err != nil {
		return nil, fmt.Errorf("create admin stats reader: %w", err)
	}
	documentStore, err := documents.NewDocumentStore(postgresPool)
	if err != nil {
		return nil, fmt.Errorf("create driver document store: %w", err)
	}
	privateObjectStore, err := miniostorage.NewObjectStore(ctx, postgresPool, config.MinIO)
	if err != nil {
		return nil, fmt.Errorf("create MinIO private object store: %w", err)
	}
	profileStore, err := userpostgres.NewProfileStore(userpostgres.ProfileRepositoryDependencies{
		Pool:          postgresPool,
		AvatarStorage: privateObjectStore,
	})
	if err != nil {
		return nil, fmt.Errorf("create profile store: %w", err)
	}
	rideStore, err := ridepostgres.NewRideStore(
		ridepostgres.RideStoreConfig{
			Pool:                  postgresPool,
			Logger:                applicationLogger,
			PlatformCommissionBPS: config.Pricing.PlatformCommissionBPS,
			OnlinePresenceMaxAge:  config.RideLifecycle.DriverLocationMaxAge,
		},
	)
	if err != nil {
		return nil, fmt.Errorf("create ride store: %w", err)
	}
	rateCounterStore := middleware.NewRedisCounterStore(redisClient)
	rateLimiter := middleware.NewRateLimiter(middleware.RateLimiterDependencies{
		Store:  rateCounterStore,
		Config: config.RateLimits,
	})
	idempotency := middleware.NewIdempotency(
		middleware.IdempotencyDependencies{
			Store: middleware.NewRedisIdempotencyStore(redisClient),
		},
		middleware.WithIdempotencyExpiration(10*time.Minute),
	).WithLogger(applicationLogger)
	routeSecurity := middleware.NewRouteSecurity(middleware.RouteSecurityDependencies{
		Config:      config.Security,
		RateLimiter: rateLimiter,
		Idempotency: idempotency,
	})
	router, eventHub, eventSubscriber := newHTTPRouter(httpRouterDependencies{
		config:             config,
		postgresPool:       postgresPool,
		redisClient:        redisClient,
		applicationLogger:  applicationLogger,
		authStore:          authStore,
		sessionStore:       sessionStore,
		rideStore:          rideStore,
		profileStore:       profileStore,
		statsReader:        statsReader,
		documentStore:      documentStore,
		privateObjectStore: privateObjectStore,
		otpAttemptStore:    rateCounterStore,
		routeSecurity:      routeSecurity,
	})
	secureHandler := middleware.SecureHTTP(router, config.Security)
	handler := proxyTrust.Middleware(middleware.Logging(applicationLogger)(secureHandler))

	application := &Application{
		server: &http.Server{
			Addr:              apiAddress(config.Host, config.Port),
			Handler:           handler,
			ReadHeaderTimeout: 5 * time.Second,
			ReadTimeout:       10 * time.Second,
			WriteTimeout:      15 * time.Second,
			IdleTimeout:       60 * time.Second,
		},
		postgresPool:    postgresPool,
		redisClient:     redisClient,
		eventHub:        eventHub,
		eventSubscriber: eventSubscriber,
		logger:          applicationLogger,
	}
	application.server.RegisterOnShutdown(eventHub.Close)
	closePostgresPool = false
	closeRedis = false
	return application, nil
}

func (application *Application) Run(ctx context.Context) error {
	if application == nil || application.server == nil || application.eventSubscriber == nil {
		return errors.New("application is not configured")
	}
	if ctx == nil {
		ctx = context.Background()
	}
	applicationLogger := application.log()
	subscriberContext, stopSubscriber := context.WithCancel(ctx)
	subscriberDone := make(chan error, 1)
	go func() {
		subscriberDone <- application.eventSubscriber.Run(subscriberContext)
	}()
	subscriberStopped := false
	defer func() {
		stopSubscriber()
		if !subscriberStopped {
			if err := <-subscriberDone; err != nil {
				applicationLogger.Warn("stop realtime event subscriber", "error", err)
			}
		}
		application.close()
	}()
	select {
	case <-application.eventSubscriber.Ready():
	case subscriberErr := <-subscriberDone:
		subscriberStopped = true
		if subscriberErr != nil {
			return fmt.Errorf("run realtime event subscriber: %w", subscriberErr)
		}
		if ctx.Err() != nil {
			return nil
		}
		return errors.New("realtime event subscriber stopped before subscribing")
	case <-ctx.Done():
		return nil
	}

	monitorContext, stopMonitoring := context.WithCancel(ctx)
	monitorDone := make(chan struct{})
	go func() {
		defer close(monitorDone)
		monitorPostgresPool(monitorContext, applicationLogger, application.postgresPool)
	}()
	defer func() {
		stopMonitoring()
		<-monitorDone
	}()

	serverErrors := make(chan error, 1)
	go func() {
		serverErrors <- application.server.ListenAndServe()
	}()
	applicationLogger.InfoContext(ctx, "api listening", "address", application.server.Addr)

	select {
	case serverErr := <-serverErrors:
		if errors.Is(serverErr, http.ErrServerClosed) {
			return nil
		}
		return fmt.Errorf("serve HTTP: %w", serverErr)
	case <-ctx.Done():
		shutdownContext, cancel := context.WithTimeout(context.WithoutCancel(ctx), 15*time.Second)
		defer cancel()
		if err := application.server.Shutdown(shutdownContext); err != nil {
			return fmt.Errorf("api shutdown failed: %w", err)
		}
		return nil
	case subscriberErr := <-subscriberDone:
		subscriberStopped = true
		if ctx.Err() != nil {
			return nil
		}
		if subscriberErr != nil {
			return fmt.Errorf("realtime event subscriber stopped: %w", subscriberErr)
		}
		return errors.New("realtime event subscriber stopped unexpectedly")
	}
}

func (application *Application) close() {
	if application.eventHub != nil {
		application.eventHub.Close()
	}
	if application.postgresPool != nil {
		application.postgresPool.Close()
	}
	if application.redisClient != nil {
		if err := application.redisClient.Close(); err != nil {
			application.log().Warn("close redis client failed", "error", err)
		}
	}
}

func (application *Application) log() *slog.Logger {
	if application != nil && application.logger != nil {
		return application.logger
	}
	return slog.Default()
}

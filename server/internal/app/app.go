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
	documentpostgres "github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/adapter/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/logger"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	redisplatform "github.com/Easy-Bao/DrivingApp/server/internal/platform/redis"
	storagepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/storage/postgres"
	websockethub "github.com/Easy-Bao/DrivingApp/server/internal/platform/websocket"
	ridepostgres "github.com/Easy-Bao/DrivingApp/server/internal/ride/adapter/postgres"
	userpostgres "github.com/Easy-Bao/DrivingApp/server/internal/user/adapter/postgres"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Application struct {
	server       *http.Server
	postgresPool *pgxpool.Pool
	redisClient  redisClient
	eventHub     *websockethub.Hub
	logger       *slog.Logger
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
		database.PostgresNativePoolConfigFromEnv(),
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

	applicationLogger := logger.New(serviceName)
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
	documentStore, err := documentpostgres.NewDocumentStore(postgresPool)
	if err != nil {
		return nil, fmt.Errorf("create driver document store: %w", err)
	}
	privateObjectStore, err := storagepostgres.NewObjectStore(postgresPool)
	if err != nil {
		return nil, fmt.Errorf("create private object store: %w", err)
	}
	profileStore, err := userpostgres.NewProfileStore(postgresPool, privateObjectStore)
	if err != nil {
		return nil, fmt.Errorf("create profile store: %w", err)
	}
	rideStore, err := ridepostgres.NewRideStore(
		postgresPool,
		config.Pricing.PlatformCommissionBPS,
	)
	if err != nil {
		return nil, fmt.Errorf("create ride store: %w", err)
	}
	router, eventHub := newHTTPRouter(httpRouterDependencies{
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
	})
	idempotency := middleware.NewIdempotency(
		middleware.NewRedisIdempotencyStore(redisClient),
		10*time.Minute,
	).WithLogger(applicationLogger)
	secureHandler := middleware.SecureHTTPWithIdempotency(
		router,
		config.Security,
		middleware.NewRateLimiterFromEnv(middleware.NewRedisCounterStore(redisClient)),
		idempotency,
	)
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
		postgresPool: postgresPool,
		redisClient:  redisClient,
		eventHub:     eventHub,
		logger:       applicationLogger,
	}
	application.server.RegisterOnShutdown(eventHub.Close)
	closePostgresPool = false
	closeRedis = false
	return application, nil
}

func (application *Application) Run(ctx context.Context) error {
	if application == nil || application.server == nil {
		return errors.New("application is not configured")
	}
	if ctx == nil {
		ctx = context.Background()
	}
	defer application.close()

	serverErrors := make(chan error, 1)
	go func() {
		serverErrors <- application.server.ListenAndServe()
	}()
	applicationLogger := application.logger
	if applicationLogger == nil {
		applicationLogger = slog.Default()
	}
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

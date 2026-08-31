package bootstrap

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/logger"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	platformmigration "github.com/Easy-Bao/DrivingApp/server/internal/platform/migration"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/hub"
)

type Application struct {
	server         *http.Server
	databaseClient *ent.Client
	redisClient    redisClient
	eventHub       *hub.Hub
	logger         *slog.Logger
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
		return nil, err
	}

	databaseClient, err := database.OpenPostgres(config.DatabaseURL)
	if err != nil {
		return nil, err
	}
	closeDatabase := true
	defer func() {
		if closeDatabase {
			_ = databaseClient.Close()
		}
	}()

	schemaContext, cancelSchemaCheck := context.WithTimeout(ctx, 15*time.Second)
	err = platformmigration.ValidateEntSchema(schemaContext, databaseClient)
	cancelSchemaCheck()
	if err != nil {
		return nil, fmt.Errorf("database schema is not ready: %w", err)
	}

	redisClient, err := database.OpenRedis(config.RedisURL)
	if err != nil {
		return nil, err
	}
	closeRedis := true
	defer func() {
		if closeRedis {
			_ = redisClient.Close()
		}
	}()

	applicationLogger := logger.New(serviceName)
	router, eventHub := newRouter(config, databaseClient, redisClient, applicationLogger)
	secureHandler := middleware.SecureHTTPWithIdempotency(
		router,
		config.Security,
		middleware.NewRateLimiterFromEnv(middleware.NewRedisCounterStore(redisClient)),
		middleware.NewIdempotency(middleware.NewRedisIdempotencyStore(redisClient), 10*time.Minute).WithLogger(applicationLogger),
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
		databaseClient: databaseClient,
		redisClient:    redisClient,
		eventHub:       eventHub,
		logger:         applicationLogger,
	}
	application.server.RegisterOnShutdown(eventHub.Close)
	closeDatabase = false
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
		return serverErr
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
	if application.databaseClient != nil {
		_ = application.databaseClient.Close()
	}
	if application.redisClient != nil {
		_ = application.redisClient.Close()
	}
}

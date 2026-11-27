package app

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"sync"
	"time"

	adminpostgres "github.com/Easy-Bao/DrivingApp/server/internal/modules/admin/adapter/postgres"
	authpostgres "github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/adapter/postgres"
	chathybrid "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/adapter/hybrid"
	chatpostgres "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/adapter/postgres"
	chatredis "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/adapter/redis"
	dispatchpostgres "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/adapter/postgres"
	documentpostgres "github.com/Easy-Bao/DrivingApp/server/internal/modules/driver/adapter/postgres"
	reviewpostgres "github.com/Easy-Bao/DrivingApp/server/internal/modules/review/adapter/postgres"
	ridepostgres "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/adapter/postgres"
	userpostgres "github.com/Easy-Bao/DrivingApp/server/internal/modules/user/adapter/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/logger"
	redisplatform "github.com/Easy-Bao/DrivingApp/server/internal/platform/redis"
	miniostorage "github.com/Easy-Bao/DrivingApp/server/internal/platform/storage/minio"
	websockethub "github.com/Easy-Bao/DrivingApp/server/internal/platform/ws"
	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	_defaultPruneRefreshInterval = 15 * time.Minute
	_defaultSweepBidInterval     = 10 * time.Second
	_defaultBackgroundTimeout    = 10 * time.Second
)

type Application struct {
	server               *http.Server
	postgresPool         *pgxpool.Pool
	redisClient          redisClient
	eventHub             *websockethub.Hub
	eventSubscriber      eventSubscriber
	migrateChatHistory   func(context.Context) error
	pruneRefreshSessions func(context.Context) (int64, error)
	pruneRefreshInterval time.Duration
	expireBidSessions    func(context.Context) (int64, error)
	expireBidInterval    time.Duration
	logger               *slog.Logger
}

type eventSubscriber interface {
	Ready() <-chan struct{}
	Run(ctx context.Context) error
}

type redisClient interface {
	Close() error
}

func New(ctx context.Context, config Config) (*Application, error) {
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
	authStore, err := authpostgres.NewUserRepository(postgresPool)
	if err != nil {
		return nil, fmt.Errorf("create auth user store: %w", err)
	}
	sessionStore, err := authpostgres.NewRefreshSessionRepository(postgresPool)
	if err != nil {
		return nil, fmt.Errorf("create auth session store: %w", err)
	}
	statsReader, err := adminpostgres.NewStatsReader(postgresPool)
	if err != nil {
		return nil, fmt.Errorf("create admin stats reader: %w", err)
	}
	documentStore, err := documentpostgres.NewDocumentRepository(postgresPool)
	if err != nil {
		return nil, fmt.Errorf("create driver document store: %w", err)
	}
	objectStoreContext, cancelObjectStore := context.WithTimeout(ctx, 15*time.Second)
	privateObjectStore, err := miniostorage.NewObjectStore(objectStoreContext, postgresPool, config.MinIO)
	cancelObjectStore()
	if err != nil {
		return nil, fmt.Errorf("create MinIO private object store: %w", err)
	}
	profileStore, err := userpostgres.NewProfileRepository(userpostgres.ProfileRepositoryDependencies{
		Pool:                       postgresPool,
		AvatarStorage:              privateObjectStore,
		AllowUnverifiedTestDrivers: config.AllowUnverifiedTestDrivers,
	})
	if err != nil {
		return nil, fmt.Errorf("create profile store: %w", err)
	}
	rideStore, err := ridepostgres.NewRideRepository(
		ridepostgres.RideRepositoryConfig{
			Pool:                       postgresPool,
			Logger:                     applicationLogger,
			PlatformCommissionBPS:      config.Pricing.PlatformCommissionBPS,
			OnlinePresenceMaxAge:       config.RideLifecycle.DriverLocationMaxAge,
			AllowUnverifiedTestDrivers: config.AllowUnverifiedTestDrivers,
		},
	)
	if err != nil {
		return nil, fmt.Errorf("create ride store: %w", err)
	}
	dispatchStore, err := dispatchpostgres.NewStore(dispatchpostgres.StoreConfig{
		Pool:                       postgresPool,
		Logger:                     applicationLogger,
		PlatformCommissionBPS:      config.Pricing.PlatformCommissionBPS,
		OnlinePresenceMaxAge:       config.RideLifecycle.DriverLocationMaxAge,
		AllowUnverifiedTestDrivers: config.AllowUnverifiedTestDrivers,
	})
	if err != nil {
		return nil, fmt.Errorf("create dispatch store: %w", err)
	}
	reviewStore, err := reviewpostgres.NewReviewRepository(postgresPool)
	if err != nil {
		return nil, fmt.Errorf("create review repository: %w", err)
	}
	rateCounterStore := middleware.NewCacheCounterStore(redisClient)
	rateLimiter := middleware.NewRateLimiter(middleware.RateLimiterDependencies{
		Store:  rateCounterStore,
		Config: config.RateLimits,
	})
	idempotency := middleware.NewIdempotency(
		middleware.IdempotencyDependencies{
			Store: middleware.NewCacheIdempotencyStore(redisClient),
		},
		middleware.WithIdempotencyExpiration(10*time.Minute),
	).WithLogger(applicationLogger)
	routeSecurity := middleware.NewRouteSecurity(middleware.RouteSecurityDependencies{
		Config:      config.Security,
		RateLimiter: rateLimiter,
		Idempotency: idempotency,
	})
	chatPostgresStore, err := chatpostgres.NewHistoryStore(postgresPool)
	if err != nil {
		return nil, fmt.Errorf("create postgresql chat store: %w", err)
	}
	chatStore, err := chathybrid.NewStore(
		chatPostgresStore,
		chatredis.NewHistoryStore(redisClient),
		chathybrid.WithLogger(applicationLogger),
	)
	if err != nil {
		return nil, fmt.Errorf("create hybrid chat store: %w", err)
	}
	router, eventHub, eventSubscriber := newHTTPRouter(httpRouterDependencies{
		config:             config,
		postgresPool:       postgresPool,
		redisClient:        redisClient,
		applicationLogger:  applicationLogger,
		authStore:          authStore,
		sessionStore:       sessionStore,
		rideStore:          rideStore,
		dispatchStore:      dispatchStore,
		reviewStore:        reviewStore,
		profileStore:       profileStore,
		statsReader:        statsReader,
		documentStore:      documentStore,
		chatStore:          chatStore,
		privateObjectStore: privateObjectStore,
		otpAttemptStore:    rateCounterStore,
		routeSecurity:      routeSecurity,
	})
	hstsMode := middleware.HSTSDisabled
	if config.Security.EnableHSTS {
		hstsMode = middleware.HSTSEnabled
	}
	handler := http.Handler(router)
	handler = middleware.RejectControlCharacters(handler)
	handler = middleware.CORS(config.Security.AllowedOrigins)(handler)
	handler = middleware.SecurityHeaders(hstsMode)(handler)
	handler = middleware.Recovery(applicationLogger)(handler)
	handler = middleware.Logging(applicationLogger)(handler)
	handler = proxyTrust.Middleware(handler)
	handler = middleware.RequestID(handler)

	application := &Application{
		server: &http.Server{
			Addr:              apiAddress(config.Host, config.Port),
			Handler:           handler,
			ReadHeaderTimeout: 5 * time.Second,
			ReadTimeout:       10 * time.Second,
			WriteTimeout:      15 * time.Second,
			IdleTimeout:       60 * time.Second,
		},
		postgresPool:       postgresPool,
		redisClient:        redisClient,
		eventHub:           eventHub,
		eventSubscriber:    eventSubscriber,
		migrateChatHistory: chatStore.MigrateLegacyRedisRooms,
		pruneRefreshSessions: func(taskCtx context.Context) (int64, error) {
			now := time.Now().UTC()
			return sessionStore.PruneExpired(taskCtx, now, now.Add(-24*time.Hour), 500)
		},
		pruneRefreshInterval: _defaultPruneRefreshInterval,
		expireBidSessions: func(taskCtx context.Context) (int64, error) {
			return dispatchStore.ExpireAllElapsedBidSessions(taskCtx, time.Now().UTC(), 200)
		},
		expireBidInterval: _defaultSweepBidInterval,
		logger:            applicationLogger,
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
	subscriberContext, stopSubscriber := context.WithCancel(context.WithoutCancel(ctx))
	subscriberDone := make(chan error, 1)
	go func() {
		subscriberDone <- application.eventSubscriber.Run(subscriberContext)
	}()
	subscriberStopped := false
	defer func() {
		stopSubscriber()
		if !subscriberStopped {
			if err := <-subscriberDone; err != nil && !errors.Is(err, context.Canceled) {
				applicationLogger.Warn("stop realtime event subscriber", "error", err)
			}
		}
		application.close()
	}()
	select {
	case <-application.eventSubscriber.Ready():
		select {
		case subscriberErr := <-subscriberDone:
			subscriberStopped = true
			return subscriberEarlyExitError(ctx, subscriberErr)
		default:
		}
	case subscriberErr := <-subscriberDone:
		subscriberStopped = true
		return subscriberEarlyExitError(ctx, subscriberErr)
	case <-ctx.Done():
		return nil
	}

	monitorContext, stopMonitoring := context.WithCancel(context.WithoutCancel(ctx))
	monitorDone := make(chan struct{})
	go func() {
		defer close(monitorDone)
		monitorPostgresPool(monitorContext, applicationLogger, application.postgresPool)
	}()
	migrationDone := make(chan struct{})
	if application.migrateChatHistory != nil {
		go func() {
			defer close(migrationDone)
			migrationContext, cancelMigration := context.WithTimeout(monitorContext, 30*time.Second)
			defer cancelMigration()
			if err := application.migrateChatHistory(migrationContext); err != nil && !errors.Is(err, context.Canceled) {
				applicationLogger.Warn("migrate legacy chat conversations failed", "error", err)
			}
		}()
	} else {
		close(migrationDone)
	}
	pruneDone := startPeriodicTask(
		monitorContext,
		applicationLogger,
		"prune expired refresh sessions",
		application.pruneRefreshInterval,
		_defaultPruneRefreshInterval,
		_defaultBackgroundTimeout,
		application.pruneRefreshSessions,
	)
	sweepBidsDone := startPeriodicTask(
		monitorContext,
		applicationLogger,
		"sweep expired bid sessions",
		application.expireBidInterval,
		_defaultSweepBidInterval,
		_defaultBackgroundTimeout,
		application.expireBidSessions,
	)
	defer func() {
		stopMonitoring()
		<-monitorDone
		<-migrationDone
		<-pruneDone
		<-sweepBidsDone
	}()

	serverErrors := make(chan error, 1)
	go func() {
		serverErrors <- application.server.ListenAndServe()
	}()
	applicationLogger.InfoContext(ctx, "api listening", "address", application.server.Addr)

	var shutdownOnce sync.Once
	var shutdownErr error
	stopServer := func() error {
		shutdownOnce.Do(func() {
			shutdownContext, cancel := context.WithTimeout(context.WithoutCancel(ctx), 15*time.Second)
			defer cancel()
			shutdownErr = application.server.Shutdown(shutdownContext)
			if shutdownErr != nil {
				if closeErr := application.server.Close(); closeErr != nil && !errors.Is(closeErr, http.ErrServerClosed) {
					shutdownErr = errors.Join(shutdownErr, closeErr)
				}
			}
			if application.eventHub != nil {
				application.eventHub.Close()
				drainContext, cancelDrain := context.WithTimeout(context.WithoutCancel(ctx), 5*time.Second)
				defer cancelDrain()
				if drainErr := application.eventHub.Wait(drainContext); drainErr != nil {
					applicationLogger.Warn("timed out waiting for websocket connections to drain", "error", drainErr)
				}
			}
		})
		return shutdownErr
	}
	defer func() {
		if err := stopServer(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			applicationLogger.Warn("stop HTTP server", "error", err)
		}
	}()

	select {
	case serverErr := <-serverErrors:
		if errors.Is(serverErr, http.ErrServerClosed) {
			return nil
		}
		return fmt.Errorf("serve HTTP: %w", serverErr)
	case <-ctx.Done():
		if err := stopServer(); err != nil {
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

func subscriberEarlyExitError(ctx context.Context, subscriberErr error) error {
	if subscriberErr != nil {
		return fmt.Errorf("run realtime event subscriber: %w", subscriberErr)
	}
	if ctx.Err() != nil {
		return nil
	}
	return errors.New("realtime event subscriber stopped before subscribing")
}

func startPeriodicTask(
	ctx context.Context,
	logger *slog.Logger,
	name string,
	interval time.Duration,
	defaultInterval time.Duration,
	timeout time.Duration,
	run func(context.Context) (int64, error),
) <-chan struct{} {
	done := make(chan struct{})
	if run == nil {
		close(done)
		return done
	}
	if interval <= 0 {
		interval = defaultInterval
	}
	go func() {
		defer close(done)
		runPeriodicTask(ctx, logger, name, interval, timeout, func(taskCtx context.Context) error {
			_, err := run(taskCtx)
			return err
		})
	}()
	return done
}

func runPeriodicTask(
	ctx context.Context,
	logger *slog.Logger,
	name string,
	interval time.Duration,
	timeout time.Duration,
	tick func(context.Context) error,
) {
	if tick == nil || interval <= 0 {
		return
	}
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			taskCtx, cancel := context.WithTimeout(ctx, timeout)
			err := tick(taskCtx)
			cancel()
			if err != nil && !errors.Is(err, context.Canceled) && logger != nil {
				logger.Warn(name+" failed", "error", err)
			}
		}
	}
}

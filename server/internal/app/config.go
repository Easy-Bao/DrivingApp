package app

import (
	"fmt"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/adapter/email"
	dispatchapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/app"
	rideconfig "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/adapter/config"
	rideapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	miniostorage "github.com/Easy-Bao/DrivingApp/server/internal/platform/storage/minio"
	"log/slog"
	"net"
	"os"
	"strings"
	"time"
)

const _serviceName = "api"

type ApplicationConfig struct {
	JWTSecret                  string
	DatabaseURL                string
	RedisURL                   string
	AllowUnverifiedTestDrivers bool
	MapboxAccessToken          string
	Host                       string
	Port                       string
	LogLevel                   slog.Level
	TrustedProxyCIDRs          string
	AdminUserIDs               string
	Security                   middleware.SecurityConfig
	RateLimits                 middleware.RateLimitConfig
	PostgresPool               database.PostgresNativePoolConfig
	Mail                       email.Config
	RideLifecycle              rideapplication.LifecycleConfig
	Bidding                    dispatchapplication.Config
	ReportingLocation          *time.Location
	MinIO                      miniostorage.Config
}

type Migration struct {
	DatabaseURL  string
	PostgresPool database.PostgresNativePoolConfig
}

type ObjectStorageMigration struct {
	Migration
	MinIO miniostorage.Config
}

type Config struct {
	ApplicationConfig
	Pricing rideapplication.PricingConfig
}

type environmentReader func(string) string

func LoadApplication() (ApplicationConfig, error) {
	return loadApplication(os.Getenv)
}

func LoadMigration() (Migration, error) {
	return loadMigration(os.Getenv)
}

func LoadObjectStorageMigration() (ObjectStorageMigration, error) {
	return loadObjectStorageMigration(os.Getenv)
}

func LoadConfig() (Config, error) {
	applicationConfig, err := LoadApplication()
	if err != nil {
		return Config{}, err
	}
	pricingConfig, err := rideconfig.LoadPricingConfig()
	if err != nil {
		return Config{}, fmt.Errorf("load ride pricing configuration: %w", err)
	}
	return Config{ApplicationConfig: applicationConfig, Pricing: pricingConfig}, nil
}

func apiAddress(host, port string) string {
	host = strings.TrimSpace(host)
	if host == "" {
		host = "127.0.0.1"
	}
	return net.JoinHostPort(host, port)
}

func loadApplication(getenv environmentReader) (ApplicationConfig, error) {
	if getenv == nil {
		return ApplicationConfig{}, fmt.Errorf("environment reader is required")
	}
	appEnvironment := strings.ToLower(strings.TrimSpace(getenv("APP_ENV")))
	allowUnverifiedTestDrivers, err := optionalBool(
		getenv,
		"ALLOW_UNVERIFIED_TEST_DRIVERS",
		false,
	)
	if err != nil {
		return ApplicationConfig{}, err
	}
	if allowUnverifiedTestDrivers && appEnvironment != "development" && appEnvironment != "test" {
		return ApplicationConfig{}, fmt.Errorf(
			"ALLOW_UNVERIFIED_TEST_DRIVERS is only allowed when APP_ENV is development or test",
		)
	}

	databaseURL, err := requiredDatabaseURL(getenv)
	if err != nil {
		return ApplicationConfig{}, err
	}
	redisURL, err := requiredValue(getenv, "REDIS_URL")
	if err != nil {
		return ApplicationConfig{}, err
	}
	jwtSecret, err := requiredValue(getenv, "JWT_SECRET")
	if err != nil {
		return ApplicationConfig{}, err
	}
	if err := security.ValidateTokenSecret(jwtSecret); err != nil {
		return ApplicationConfig{}, fmt.Errorf("validate JWT secret: %w", err)
	}
	port, err := requiredPort(getenv, "API_PORT")
	if err != nil {
		return ApplicationConfig{}, err
	}

	poolConfig, err := loadPostgresPoolConfig(getenv)
	if err != nil {
		return ApplicationConfig{}, fmt.Errorf("load PostgreSQL pool configuration: %w", err)
	}
	mailConfig, err := loadMailConfig(getenv)
	if err != nil {
		return ApplicationConfig{}, fmt.Errorf("load mail configuration: %w", err)
	}
	securityConfig, err := loadSecurityConfig(getenv)
	if err != nil {
		return ApplicationConfig{}, fmt.Errorf("load HTTP security configuration: %w", err)
	}
	rateLimitConfig, err := loadRateLimitConfig(getenv)
	if err != nil {
		return ApplicationConfig{}, fmt.Errorf("load rate-limit configuration: %w", err)
	}
	minioConfig, err := loadMinIOConfig(getenv)
	if err != nil {
		return ApplicationConfig{}, fmt.Errorf("load MinIO configuration: %w", err)
	}
	rideLifecycleConfig, err := loadRideLifecycleConfig(getenv)
	if err != nil {
		return ApplicationConfig{}, fmt.Errorf("load ride lifecycle configuration: %w", err)
	}
	biddingConfig, err := loadBiddingConfig(getenv)
	if err != nil {
		return ApplicationConfig{}, fmt.Errorf("load ride bidding configuration: %w", err)
	}
	reportingLocation, err := rideapplication.LoadReportingLocation(getenv("REPORTING_TIMEZONE"))
	if err != nil {
		return ApplicationConfig{}, fmt.Errorf("load reporting timezone: %w", err)
	}

	return ApplicationConfig{
		JWTSecret:                  jwtSecret,
		DatabaseURL:                databaseURL,
		RedisURL:                   redisURL,
		AllowUnverifiedTestDrivers: allowUnverifiedTestDrivers,
		MapboxAccessToken:          strings.TrimSpace(getenv("MAPBOX_ACCESS_TOKEN")),
		Host:                       valueOrDefault(getenv, "API_HOST", "127.0.0.1"),
		Port:                       port,
		LogLevel:                   logLevel(getenv("LOG_LEVEL")),
		TrustedProxyCIDRs:          strings.TrimSpace(getenv("TRUSTED_PROXY_CIDRS")),
		AdminUserIDs:               strings.TrimSpace(getenv("ADMIN_USER_IDS")),
		Security:                   securityConfig,
		RateLimits:                 rateLimitConfig,
		PostgresPool:               poolConfig,
		Mail:                       mailConfig,
		RideLifecycle:              rideLifecycleConfig,
		Bidding:                    biddingConfig,
		ReportingLocation:          reportingLocation,
		MinIO:                      minioConfig,
	}, nil
}

func loadMigration(getenv environmentReader) (Migration, error) {
	if getenv == nil {
		return Migration{}, fmt.Errorf("environment reader is required")
	}
	databaseURL, err := requiredDatabaseURL(getenv)
	if err != nil {
		return Migration{}, err
	}
	poolConfig, err := loadPostgresPoolConfig(getenv)
	if err != nil {
		return Migration{}, fmt.Errorf("load PostgreSQL pool configuration: %w", err)
	}
	return Migration{DatabaseURL: databaseURL, PostgresPool: poolConfig}, nil
}

func loadObjectStorageMigration(getenv environmentReader) (ObjectStorageMigration, error) {
	migrationConfig, err := loadMigration(getenv)
	if err != nil {
		return ObjectStorageMigration{}, err
	}
	minioConfig, err := loadMinIOConfig(getenv)
	if err != nil {
		return ObjectStorageMigration{}, fmt.Errorf("load MinIO configuration: %w", err)
	}
	return ObjectStorageMigration{Migration: migrationConfig, MinIO: minioConfig}, nil
}

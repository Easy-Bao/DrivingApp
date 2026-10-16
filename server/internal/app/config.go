package app

import (
	"errors"
	"fmt"
	"log/slog"
	"math"
	"net"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/email"
	dispatchapplication "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	miniostorage "github.com/Easy-Bao/DrivingApp/server/internal/platform/storage/minio"
	rideconfig "github.com/Easy-Bao/DrivingApp/server/internal/ride/adapter/config"
	rideapplication "github.com/Easy-Bao/DrivingApp/server/internal/ride/app"
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

func loadPostgresPoolConfig(getenv environmentReader) (database.PostgresNativePoolConfig, error) {
	config := database.DefaultPostgresNativePoolConfig()
	var err error
	if config.MaxConnections, err = optionalInt32(getenv, "POSTGRES_MAX_OPEN_CONNECTIONS", config.MaxConnections, 1); err != nil {
		return database.PostgresNativePoolConfig{}, err
	}
	if config.MinConnections, err = optionalInt32(getenv, "POSTGRES_MIN_CONNECTIONS", config.MinConnections, 0); err != nil {
		return database.PostgresNativePoolConfig{}, err
	}
	if config.MinIdleConnections, err = optionalInt32(getenv, "POSTGRES_MIN_IDLE_CONNECTIONS", config.MinIdleConnections, 0); err != nil {
		return database.PostgresNativePoolConfig{}, err
	}
	if config.ConnectionMaxLifetime, err = optionalDuration(getenv, "POSTGRES_CONNECTION_MAX_LIFETIME", config.ConnectionMaxLifetime, time.Nanosecond); err != nil {
		return database.PostgresNativePoolConfig{}, err
	}
	if config.ConnectionMaxIdleTime, err = optionalDuration(getenv, "POSTGRES_CONNECTION_MAX_IDLE_TIME", config.ConnectionMaxIdleTime, time.Nanosecond); err != nil {
		return database.PostgresNativePoolConfig{}, err
	}
	if config.PingTimeout, err = optionalDuration(getenv, "POSTGRES_PING_TIMEOUT", config.PingTimeout, time.Nanosecond); err != nil {
		return database.PostgresNativePoolConfig{}, err
	}
	if err := config.Validate(); err != nil {
		return database.PostgresNativePoolConfig{}, err
	}
	return config, nil
}

func loadMailConfig(getenv environmentReader) (email.Config, error) {
	config := email.Config{
		Host:     strings.TrimSpace(getenv("MAIL_HOST")),
		Username: strings.TrimSpace(getenv("MAIL_USERNAME")),
		Password: getenv("MAIL_PASSWORD"),
		From:     strings.TrimSpace(getenv("MAIL_FROM")),
		FromName: valueOrDefault(getenv, "MAIL_FROM_NAME", "DriveApp"),
		Subject:  valueOrDefault(getenv, "MAIL_SUBJECT", "DriveApp verification code"),
		Security: strings.ToLower(valueOrDefault(getenv, "MAIL_SECURITY", "starttls")),
		Timeout:  10 * time.Second,
	}
	var err error
	if config.Port, err = optionalInt(getenv, "MAIL_PORT", 0, 0, 65535); err != nil {
		return email.Config{}, err
	}
	if config.Timeout, err = optionalDuration(getenv, "MAIL_TIMEOUT", config.Timeout, time.Nanosecond); err != nil {
		return email.Config{}, err
	}

	if err := config.ValidateSettings(); err != nil {
		return email.Config{}, err
	}
	if err := config.Validate(); err != nil && !errors.Is(err, email.ErrNotConfigured) {
		return email.Config{}, err
	}
	return config, nil
}

func loadSecurityConfig(getenv environmentReader) (middleware.SecurityConfig, error) {
	config := middleware.DefaultSecurityConfig()
	config.AllowedOrigins = parseOrigins(getenv("CORS_ALLOWED_ORIGINS"))
	var err error
	if config.EnableHSTS, err = optionalBool(getenv, "ENABLE_HSTS", false); err != nil {
		return middleware.SecurityConfig{}, err
	}
	if config.JSONBodyLimit, err = optionalInt64(getenv, "JSON_BODY_LIMIT_BYTES", config.JSONBodyLimit, 1); err != nil {
		return middleware.SecurityConfig{}, err
	}
	if config.UploadBodyLimit, err = optionalInt64(getenv, "UPLOAD_BODY_LIMIT_BYTES", config.UploadBodyLimit, 1); err != nil {
		return middleware.SecurityConfig{}, err
	}
	return config, nil
}

func loadRateLimitConfig(getenv environmentReader) (middleware.RateLimitConfig, error) {
	config := middleware.DefaultRateLimitConfig()
	values := []struct {
		key   string
		field *int64
	}{
		{"AUTH_RATE_LIMIT_REQUESTS_PER_MINUTE", &config.Authentication},
		{"REFRESH_RATE_LIMIT_REQUESTS_PER_MINUTE", &config.Refresh},
		{"LOCATION_RATE_LIMIT_REQUESTS_PER_MINUTE", &config.Location},
		{"FARE_RATE_LIMIT_REQUESTS_PER_MINUTE", &config.Fare},
		{"CONNECTION_RATE_LIMIT_REQUESTS_PER_MINUTE", &config.Connection},
		{"TELEMETRY_RATE_LIMIT_REQUESTS_PER_MINUTE", &config.Telemetry},
		{"MUTATION_RATE_LIMIT_REQUESTS_PER_MINUTE", &config.Mutation},
		{"READ_RATE_LIMIT_REQUESTS_PER_MINUTE", &config.Read},
	}
	for _, value := range values {
		parsed, err := optionalInt64(getenv, value.key, *value.field, 1)
		if err != nil {
			return middleware.RateLimitConfig{}, err
		}
		*value.field = parsed
	}
	return config, nil
}

func loadMinIOConfig(getenv environmentReader) (miniostorage.Config, error) {
	endpoint, err := requiredValue(getenv, "MINIO_ENDPOINT")
	if err != nil {
		return miniostorage.Config{}, err
	}
	accessKey, err := requiredValue(getenv, "MINIO_ACCESS_KEY")
	if err != nil {
		return miniostorage.Config{}, err
	}
	secretKey, err := requiredValue(getenv, "MINIO_SECRET_KEY")
	if err != nil {
		return miniostorage.Config{}, err
	}
	bucket, err := requiredValue(getenv, "MINIO_BUCKET")
	if err != nil {
		return miniostorage.Config{}, err
	}
	secure, err := optionalBool(getenv, "MINIO_USE_SSL", false)
	if err != nil {
		return miniostorage.Config{}, err
	}
	config := miniostorage.Config{
		Endpoint:  endpoint,
		AccessKey: accessKey,
		SecretKey: secretKey,
		Bucket:    bucket,
		Secure:    secure,
	}
	if err := config.Validate(); err != nil {
		return miniostorage.Config{}, err
	}
	return config, nil
}

func loadRideLifecycleConfig(getenv environmentReader) (rideapplication.LifecycleConfig, error) {
	config := rideapplication.DefaultLifecycleConfig()
	var err error
	if config.PassengerWaitDuration, err = optionalWholeSecondDuration(getenv, "PASSENGER_NO_SHOW_WAIT", config.PassengerWaitDuration); err != nil {
		return rideapplication.LifecycleConfig{}, err
	}
	if config.DriverLocationMaxAge, err = optionalWholeSecondDuration(getenv, "DRIVER_LOCATION_MAX_AGE", config.DriverLocationMaxAge); err != nil {
		return rideapplication.LifecycleConfig{}, err
	}
	if config.ArrivalRadiusMeters, err = optionalPositiveFloat(getenv, "RIDE_ARRIVAL_RADIUS_METERS", config.ArrivalRadiusMeters); err != nil {
		return rideapplication.LifecycleConfig{}, err
	}
	if config.CompletionRadiusMeters, err = optionalPositiveFloat(getenv, "RIDE_COMPLETION_RADIUS_METERS", config.CompletionRadiusMeters); err != nil {
		return rideapplication.LifecycleConfig{}, err
	}
	return config, nil
}

func loadBiddingConfig(getenv environmentReader) (dispatchapplication.Config, error) {
	config := dispatchapplication.DefaultConfig()
	duration, err := optionalWholeSecondDuration(getenv, "BID_SESSION_DURATION", config.SessionDuration)
	if err != nil {
		return dispatchapplication.Config{}, err
	}
	config.SessionDuration = duration
	return config, nil
}

func requiredValue(getenv environmentReader, key string) (string, error) {
	value := strings.TrimSpace(getenv(key))
	if value == "" {
		return "", fmt.Errorf("%s is required", key)
	}
	return value, nil
}

func requiredDatabaseURL(getenv environmentReader) (string, error) {
	value := strings.TrimSpace(getenv("DATABASE_URL"))
	if value == "" {
		return "", errors.New("database url is required")
	}
	return value, nil
}

func requiredPort(getenv environmentReader, key string) (string, error) {
	value, err := requiredValue(getenv, key)
	if err != nil {
		return "", err
	}
	port, err := strconv.Atoi(value)
	if err != nil || port < 1 || port > 65535 {
		return "", fmt.Errorf("%s must be an integer between 1 and 65535", key)
	}
	return value, nil
}

func valueOrDefault(getenv environmentReader, key, fallback string) string {
	if value := strings.TrimSpace(getenv(key)); value != "" {
		return value
	}
	return fallback
}

func optionalInt(getenv environmentReader, key string, fallback, minimum, maximum int) (int, error) {
	raw := strings.TrimSpace(getenv(key))
	if raw == "" {
		return fallback, nil
	}
	value, err := strconv.ParseInt(raw, 10, 32)
	if err != nil || value < int64(minimum) || value > int64(maximum) {
		return 0, fmt.Errorf("%s must be an integer between %d and %d", key, minimum, maximum)
	}
	return int(value), nil
}

func optionalInt32(getenv environmentReader, key string, fallback int32, minimum int64) (int32, error) {
	raw := strings.TrimSpace(getenv(key))
	if raw == "" {
		return fallback, nil
	}
	value, err := strconv.ParseInt(raw, 10, 32)
	if err != nil || value < minimum {
		return 0, fmt.Errorf("%s must be an integer greater than or equal to %d", key, minimum)
	}
	return int32(value), nil
}

func optionalInt64(getenv environmentReader, key string, fallback, minimum int64) (int64, error) {
	raw := strings.TrimSpace(getenv(key))
	if raw == "" {
		return fallback, nil
	}
	value, err := strconv.ParseInt(raw, 10, 64)
	if err != nil || value < minimum {
		return 0, fmt.Errorf("%s must be an integer greater than or equal to %d", key, minimum)
	}
	return value, nil
}

func optionalDuration(getenv environmentReader, key string, fallback, minimum time.Duration) (time.Duration, error) {
	raw := strings.TrimSpace(getenv(key))
	if raw == "" {
		return fallback, nil
	}
	value, err := time.ParseDuration(raw)
	if err != nil || value < minimum {
		return 0, fmt.Errorf("%s must be a duration of at least %s", key, minimum)
	}
	return value, nil
}

func optionalWholeSecondDuration(getenv environmentReader, key string, fallback time.Duration) (time.Duration, error) {
	raw := strings.TrimSpace(getenv(key))
	if raw == "" {
		return fallback, nil
	}
	value, err := time.ParseDuration(raw)
	seconds := value / time.Second
	if err != nil || value <= 0 || value%time.Second != 0 || seconds > 1<<31-1 {
		return 0, fmt.Errorf("%s must be a positive whole-second duration", key)
	}
	return value, nil
}

func optionalPositiveFloat(getenv environmentReader, key string, fallback float64) (float64, error) {
	raw := strings.TrimSpace(getenv(key))
	if raw == "" {
		return fallback, nil
	}
	value, err := strconv.ParseFloat(raw, 64)
	if err != nil || value <= 0 || math.IsNaN(value) || math.IsInf(value, 0) {
		return 0, fmt.Errorf("%s must be a finite positive number", key)
	}
	return value, nil
}

func optionalBool(getenv environmentReader, key string, fallback bool) (bool, error) {
	raw := strings.TrimSpace(getenv(key))
	if raw == "" {
		return fallback, nil
	}
	value, err := strconv.ParseBool(raw)
	if err != nil {
		return false, fmt.Errorf("%s must be a boolean", key)
	}
	return value, nil
}

func parseOrigins(raw string) []string {
	values := strings.Split(raw, ",")
	origins := make([]string, 0, len(values))
	for _, value := range values {
		if origin := strings.TrimSpace(value); origin != "" {
			origins = append(origins, origin)
		}
	}
	return origins
}

func logLevel(raw string) slog.Level {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "debug":
		return slog.LevelDebug
	case "warn", "warning":
		return slog.LevelWarn
	case "error":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}

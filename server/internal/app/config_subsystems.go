package app

import (
	"errors"
	"fmt"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/adapter/email"
	dispatchapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/app"
	rideapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/httpx/middleware"
	miniostorage "github.com/Easy-Bao/DrivingApp/server/internal/platform/storage/minio"
	"strings"
	"time"
)

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
	if config.UploadBodyLimit > miniostorage.MaxObjectBytes {
		return middleware.SecurityConfig{}, fmt.Errorf(
			"UPLOAD_BODY_LIMIT_BYTES must be at most %d",
			miniostorage.MaxObjectBytes,
		)
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

package app

import (
	"errors"
	"fmt"
	"math"
	"net"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	rideconfig "github.com/Easy-Bao/DrivingApp/server/internal/ride/adapter/config"
	rideapplication "github.com/Easy-Bao/DrivingApp/server/internal/ride/application"
	ridelifecycle "github.com/Easy-Bao/DrivingApp/server/internal/ride/lifecycle"
)

const _serviceName = "api"

type Config struct {
	JWTSecret         string
	DatabaseURL       string
	RedisURL          string
	MapboxAccessToken string
	Host              string
	Port              string
	TrustedProxyCIDRs string
	AdminUserIDs      string
	Security          middleware.SecurityConfig
	Pricing           rideapplication.PricingConfig
	RideLifecycle     ridelifecycle.Config
	ReportingLocation *time.Location
}

func LoadConfig() (Config, error) {
	jwtSecret := strings.TrimSpace(os.Getenv("JWT_SECRET"))
	if err := security.ValidateTokenSecret(jwtSecret); err != nil {
		return Config{}, fmt.Errorf("validate JWT secret: %w", err)
	}

	databaseURL, err := requiredEnv("DATABASE_URL")
	if err != nil {
		return Config{}, fmt.Errorf("load database URL: %w", err)
	}
	redisURL, err := requiredEnv("REDIS_URL")
	if err != nil {
		return Config{}, fmt.Errorf("load redis URL: %w", err)
	}

	port, err := requiredPortEnv("API_PORT")
	if err != nil {
		return Config{}, fmt.Errorf("load API port: %w", err)
	}

	pricing, err := rideconfig.LoadPricingConfig()
	if err != nil {
		return Config{}, fmt.Errorf("load pricing configuration: %w", err)
	}
	rideLifecycle, err := loadRideLifecycleConfig(os.Getenv)
	if err != nil {
		return Config{}, fmt.Errorf("load ride lifecycle configuration: %w", err)
	}
	reportingLocation, err := rideapplication.LoadReportingLocation(os.Getenv("REPORTING_TIMEZONE"))
	if err != nil {
		return Config{}, fmt.Errorf("load reporting timezone: %w", err)
	}

	return Config{
		JWTSecret:         jwtSecret,
		DatabaseURL:       databaseURL,
		RedisURL:          redisURL,
		MapboxAccessToken: os.Getenv("MAPBOX_ACCESS_TOKEN"),
		Host:              apiHost(),
		Port:              port,
		TrustedProxyCIDRs: os.Getenv("TRUSTED_PROXY_CIDRS"),
		AdminUserIDs:      os.Getenv("ADMIN_USER_IDS"),
		Security:          middleware.SecurityConfigFromEnv(),
		Pricing:           pricing,
		RideLifecycle:     rideLifecycle,
		ReportingLocation: reportingLocation,
	}, nil
}

func loadRideLifecycleConfig(getenv func(string) string) (ridelifecycle.Config, error) {
	config := ridelifecycle.DefaultConfig()
	raw := strings.TrimSpace(getenv("PASSENGER_NO_SHOW_WAIT"))
	if raw != "" {
		duration, err := time.ParseDuration(raw)
		seconds := duration / time.Second
		invalid := err != nil || duration <= 0 || duration%time.Second != 0 || seconds > 1<<31-1
		if invalid {
			return ridelifecycle.Config{}, errors.New(
				"PASSENGER_NO_SHOW_WAIT must be a positive whole-second duration",
			)
		}
		config.PassengerWaitDuration = duration
	}

	arrivalRadius, err := positiveFloatEnv(
		getenv,
		"RIDE_ARRIVAL_RADIUS_METERS",
		config.ArrivalRadiusMeters,
	)
	if err != nil {
		return ridelifecycle.Config{}, err
	}
	completionRadius, err := positiveFloatEnv(
		getenv,
		"RIDE_COMPLETION_RADIUS_METERS",
		config.CompletionRadiusMeters,
	)
	if err != nil {
		return ridelifecycle.Config{}, err
	}
	config.ArrivalRadiusMeters = arrivalRadius
	config.CompletionRadiusMeters = completionRadius
	return config, nil
}

func positiveFloatEnv(getenv func(string) string, key string, fallback float64) (float64, error) {
	raw := strings.TrimSpace(getenv(key))
	if raw == "" {
		return fallback, nil
	}
	value, err := strconv.ParseFloat(raw, 64)
	if err != nil || value <= 0 || math.IsNaN(value) || math.IsInf(value, 0) {
		return 0, fmt.Errorf("%s must be a positive finite number", key)
	}
	return value, nil
}

func apiHost() string {
	if value := strings.TrimSpace(os.Getenv("API_HOST")); value != "" {
		return value
	}
	return "127.0.0.1"
}

func apiAddress(host, port string) string {
	return net.JoinHostPort(host, port)
}

func requiredPortEnv(key string) (string, error) {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return "", fmt.Errorf("%s is required", key)
	}
	port, err := strconv.Atoi(value)
	invalidPort := err != nil || port < 1 || port > 65535
	if invalidPort {
		return "", fmt.Errorf("%s must be between 1 and 65535", key)
	}
	return value, nil
}

func requiredEnv(key string) (string, error) {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return "", fmt.Errorf("%s is required", key)
	}
	return value, nil
}

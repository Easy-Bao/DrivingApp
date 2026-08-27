package bootstrap

import (
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	ridesusecase "github.com/Easy-Bao/DrivingApp/server/internal/rides/usecase"
)

const serviceName = "api"

type Config struct {
	JWTSecret         string
	DatabaseURL       string
	RedisURL          string
	MapboxAccessToken string
	Port              string
	TrustedProxyCIDRs string
	AdminUserIDs      string
	Security          middleware.SecurityConfig
	Pricing           ridesusecase.PricingConfig
	ReportingLocation *time.Location
}

func LoadConfig() (Config, error) {
	jwtSecret := strings.TrimSpace(os.Getenv("JWT_SECRET"))
	if err := security.ValidateTokenSecret(jwtSecret); err != nil {
		return Config{}, err
	}

	databaseURL, err := requiredEnv("DATABASE_URL")
	if err != nil {
		return Config{}, err
	}
	redisURL, err := requiredEnv("REDIS_URL")
	if err != nil {
		return Config{}, err
	}

	pricing, err := ridesusecase.LoadPricingConfig()
	if err != nil {
		return Config{}, err
	}
	reportingLocation, err := ridesusecase.LoadReportingLocation(os.Getenv("REPORTING_TIMEZONE"))
	if err != nil {
		return Config{}, err
	}

	return Config{
		JWTSecret:         jwtSecret,
		DatabaseURL:       databaseURL,
		RedisURL:          redisURL,
		MapboxAccessToken: os.Getenv("MAPBOX_ACCESS_TOKEN"),
		Port:              apiPort(),
		TrustedProxyCIDRs: os.Getenv("TRUSTED_PROXY_CIDRS"),
		AdminUserIDs:      os.Getenv("ADMIN_USER_IDS"),
		Security:          middleware.SecurityConfigFromEnv(),
		Pricing:           pricing,
		ReportingLocation: reportingLocation,
	}, nil
}

func requiredEnv(key string) (string, error) {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return "", fmt.Errorf("%s is required", key)
	}
	return value, nil
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

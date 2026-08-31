package bootstrap

import (
	"fmt"
	"net"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	rideapplication "github.com/Easy-Bao/DrivingApp/server/internal/ride/application"
)

const serviceName = "api"

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

	port, err := requiredPortEnv("API_PORT")
	if err != nil {
		return Config{}, err
	}

	pricing, err := rideapplication.LoadPricingConfig()
	if err != nil {
		return Config{}, err
	}
	reportingLocation, err := rideapplication.LoadReportingLocation(os.Getenv("REPORTING_TIMEZONE"))
	if err != nil {
		return Config{}, err
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
		ReportingLocation: reportingLocation,
	}, nil
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
	if err != nil || port < 1 || port > 65535 {
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

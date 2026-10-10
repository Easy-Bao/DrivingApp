package app

import (
	"fmt"
	"net"
	"strings"

	environmentconfig "github.com/Easy-Bao/DrivingApp/server/internal/config"
	rideconfig "github.com/Easy-Bao/DrivingApp/server/internal/ride/adapter/config"
	rideapplication "github.com/Easy-Bao/DrivingApp/server/internal/ride/application"
)

const _serviceName = "api"

type Config struct {
	environmentconfig.Application
	Pricing rideapplication.PricingConfig
}

func LoadConfig() (Config, error) {
	applicationConfig, err := environmentconfig.LoadApplication()
	if err != nil {
		return Config{}, err
	}
	pricingConfig, err := rideconfig.LoadPricingConfig()
	if err != nil {
		return Config{}, fmt.Errorf("load ride pricing configuration: %w", err)
	}
	return Config{Application: applicationConfig, Pricing: pricingConfig}, nil
}

func apiAddress(host, port string) string {
	host = strings.TrimSpace(host)
	if host == "" {
		host = "127.0.0.1"
	}
	return net.JoinHostPort(host, port)
}

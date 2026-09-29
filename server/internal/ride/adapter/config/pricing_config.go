package config

import (
	_ "embed"
	"encoding/json"
	"fmt"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/application"
)

//go:embed pricing_config.json
var _pricingConfigJSON []byte

func LoadPricingConfig() (application.PricingConfig, error) {
	var config application.PricingConfig
	if err := json.Unmarshal(_pricingConfigJSON, &config); err != nil {
		return application.PricingConfig{}, fmt.Errorf("decode pricing configuration: %w", err)
	}
	if err := config.Validate(); err != nil {
		return application.PricingConfig{}, err
	}
	return config, nil
}

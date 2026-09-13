package application

import (
	_ "embed"
	"encoding/json"
	"fmt"
	"math"
)

//go:embed pricing_config.json
var pricingConfigJSON []byte

type RatingPricingConfig struct {
	MinimumRatingThreshold          float64 `json:"minimumRatingThreshold"`
	HighRatingBonusMultiplier       float64 `json:"highRatingBonusMultiplier"`
	LowRatingSurgePenaltyMultiplier float64 `json:"lowRatingSurgePenaltyMultiplier"`
	BaseSurgeCap                    float64 `json:"baseSurgeCap"`
}

type PricingConfig struct {
	BaseFareAmount        int64               `json:"baseFareAmount"`
	PerKilometerAmount    int64               `json:"perKilometerAmount"`
	PerMinuteAmount       int64               `json:"perMinuteAmount"`
	PlatformCommissionBPS int64               `json:"platformCommissionBPS"`
	RatingPricingConfig   RatingPricingConfig `json:"ratingPricingConfig"`
}

func LoadPricingConfig() (PricingConfig, error) {
	var config PricingConfig
	if err := json.Unmarshal(pricingConfigJSON, &config); err != nil {
		return PricingConfig{}, fmt.Errorf("decode pricing configuration: %w", err)
	}
	if err := config.Validate(); err != nil {
		return PricingConfig{}, err
	}
	return config, nil
}

func (config PricingConfig) Validate() error {
	if config.BaseFareAmount <= 0 {
		return fmt.Errorf("base fare must be greater than zero")
	}
	if config.PerKilometerAmount < 0 {
		return fmt.Errorf("per-kilometer fare cannot be negative")
	}
	if config.PerMinuteAmount < 0 {
		return fmt.Errorf("per-minute fare cannot be negative")
	}
	if config.PlatformCommissionBPS < 0 || config.PlatformCommissionBPS > 10000 {
		return fmt.Errorf("platform commission must be between 0 and 10000 basis points")
	}

	rating := config.RatingPricingConfig
	if rating.MinimumRatingThreshold < 0 || rating.MinimumRatingThreshold > 5 {
		return fmt.Errorf("minimum rating threshold must be between 0 and 5")
	}
	if !isFinitePositive(rating.HighRatingBonusMultiplier) {
		return fmt.Errorf("high-rating bonus multiplier must be finite and greater than zero")
	}
	if !isFinitePositive(rating.LowRatingSurgePenaltyMultiplier) {
		return fmt.Errorf("low-rating penalty multiplier must be finite and greater than zero")
	}
	if !isFinitePositive(rating.BaseSurgeCap) {
		return fmt.Errorf("base surge cap must be finite and greater than zero")
	}
	return nil
}

func (config PricingConfig) FareAmount(distanceKm, durationMinutes float64) int64 {
	if !isFiniteNonNegative(distanceKm) || !isFiniteNonNegative(durationMinutes) {
		return 0
	}

	total := float64(config.BaseFareAmount) +
		distanceKm*float64(config.PerKilometerAmount) +
		durationMinutes*float64(config.PerMinuteAmount)
	if total < float64(config.BaseFareAmount) {
		total = float64(config.BaseFareAmount)
	}
	return int64(total)
}

func (config PricingConfig) ServiceConfigJSON() map[string]any {
	return map[string]any{
		"id":                  "solo",
		"serviceName":         "Solo Ride",
		"baseFare":            float64(config.BaseFareAmount) / 100,
		"perKmRate":           float64(config.PerKilometerAmount) / 100,
		"perMinuteRate":       float64(config.PerMinuteAmount) / 100,
		"ratingPricingConfig": config.RatingPricingConfig,
	}
}

func (config PricingConfig) FareConfigsJSON() map[string]any {
	service := config.ServiceConfigJSON()
	service["base_fare_amount"] = config.BaseFareAmount
	service["per_kilometer_amount"] = config.PerKilometerAmount
	service["per_minute_amount"] = config.PerMinuteAmount
	service["platform_commission_bps"] = config.PlatformCommissionBPS
	service["rating_pricing_config"] = config.RatingPricingConfig
	return service
}

func (config PricingConfig) RatingConfigJSON() RatingPricingConfig {
	return config.RatingPricingConfig
}

func isFinitePositive(value float64) bool {
	return !math.IsNaN(value) && !math.IsInf(value, 0) && value > 0
}

func isFiniteNonNegative(value float64) bool {
	return !math.IsNaN(value) && !math.IsInf(value, 0) && value >= 0
}

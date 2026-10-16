package config

import "testing"

func TestLoadPricingConfigReadsTheServerSource(t *testing.T) {
	config, err := LoadPricingConfig()
	if err != nil {
		t.Fatalf("LoadPricingConfig returned error: %v", err)
	}
	if config.BaseFareAmount != 2500 ||
		config.PerKilometerAmount != 100 ||
		config.PerMinuteAmount != 50 {
		t.Fatalf("unexpected fare configuration: %#v", config)
	}
	if config.RatingPricingConfig.MinimumRatingThreshold != 4.5 {
		t.Fatalf("unexpected rating configuration: %#v", config.RatingPricingConfig)
	}
}

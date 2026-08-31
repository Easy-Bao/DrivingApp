package application

import "testing"

func TestLoadPricingConfigReadsTheServerSource(t *testing.T) {
	config, err := LoadPricingConfig()
	if err != nil {
		t.Fatalf("LoadPricingConfig returned error: %v", err)
	}
	if config.BaseFareCentavos != 2500 ||
		config.PerKilometerCentavos != 100 ||
		config.PerMinuteCentavos != 50 {
		t.Fatalf("unexpected fare configuration: %#v", config)
	}
	if config.RatingPricingConfig.MinimumRatingThreshold != 4.5 {
		t.Fatalf("unexpected rating configuration: %#v", config.RatingPricingConfig)
	}
}

func TestPricingConfigCalculatesFareFromLoadedValues(t *testing.T) {
	config := PricingConfig{
		BaseFareCentavos:      1000,
		PerKilometerCentavos:  200,
		PerMinuteCentavos:     100,
		PlatformCommissionBPS: 1500,
		RatingPricingConfig: RatingPricingConfig{
			MinimumRatingThreshold:          4,
			HighRatingBonusMultiplier:       1.1,
			LowRatingSurgePenaltyMultiplier: 0.9,
			BaseSurgeCap:                    2,
		},
	}
	if err := config.Validate(); err != nil {
		t.Fatalf("config.Validate returned error: %v", err)
	}
	if got := config.FareCentavos(2, 3); got != 1700 {
		t.Fatalf("fare = %d, want 1700", got)
	}
}

func TestPricingConfigRejectsInvalidValues(t *testing.T) {
	config := PricingConfig{
		BaseFareCentavos: 0,
		RatingPricingConfig: RatingPricingConfig{
			HighRatingBonusMultiplier:       1,
			LowRatingSurgePenaltyMultiplier: 1,
			BaseSurgeCap:                    1,
		},
	}
	if err := config.Validate(); err == nil {
		t.Fatal("expected invalid pricing configuration to be rejected")
	}
}

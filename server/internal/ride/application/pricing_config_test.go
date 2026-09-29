package application

import "testing"

func TestPricingConfigCalculatesFareFromLoadedValues(t *testing.T) {
	config := PricingConfig{
		BaseFareAmount:        1000,
		PerKilometerAmount:    200,
		PerMinuteAmount:       100,
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
	if got := config.FareAmount(2, 3); got != 1700 {
		t.Fatalf("fare = %d, want 1700", got)
	}
}

func TestPricingConfigRejectsInvalidValues(t *testing.T) {
	config := PricingConfig{
		BaseFareAmount: 0,
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

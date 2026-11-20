package app

import (
	"math"
	"testing"
)

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

func TestPricingConfigFareAmountRoundsAndGuardsOverflow(t *testing.T) {
	config := PricingConfig{
		BaseFareAmount:     1000,
		PerKilometerAmount: 300,
		PerMinuteAmount:    100,
	}
	// 1000 + 1.9999999999999998*300 = 1600 (not truncated to 1599).
	if got := config.FareAmount(1.9999999999999998, 0); got != 1600 {
		t.Fatalf("FareAmount rounded = %d, want 1600", got)
	}
	if got := config.FareAmount(math.MaxFloat64, 0); got != 0 {
		t.Fatalf("FareAmount overflow = %d, want 0", got)
	}
	if got := config.FareAmount(math.NaN(), 1); got != 0 {
		t.Fatalf("FareAmount NaN = %d, want 0", got)
	}
}

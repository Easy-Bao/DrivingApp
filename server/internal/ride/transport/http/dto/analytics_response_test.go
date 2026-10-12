package dto

import (
	"encoding/json"
	"reflect"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

func TestNewDriverStatsResponsePreservesWireFields(t *testing.T) {
	stats := domain.DriverStats{
		DriverID:            7,
		TotalTrips:          14,
		CompletedTrips:      11,
		ActiveTrips:         1,
		TotalEarnings:       9000,
		TodayCompletedTrips: 2,
		TodayEarnings:       2400,
		AverageRating:       4.7,
		RatingDistribution:  [5]int{0, 1, 1, 3, 6},
		Standing: domain.DriverStanding{
			SettledTrips:                       12,
			DriverFaultCancellations:           1,
			PassengerFaultCancellations:        2,
			SystemFaultCancellations:           1,
			NoFaultCancellations:               1,
			SafetyRelatedCancellations:         1,
			PendingReviewCancellations:         1,
			AdminOverrideCancellations:         0,
			CompletionRatePercent:              91.6,
			DriverFaultCancellationRatePercent: 8.3,
		},
	}

	got := marshalResponseMap(t, NewDriverStatsResponse(stats))
	want := map[string]any{
		"driver_id":             float64(7),
		"total_trips":           float64(14),
		"completed_trips":       float64(11),
		"active_trips":          float64(1),
		"total_earnings_amount": float64(9000),
		"today_completed_trips": float64(2),
		"today_earnings_amount": float64(2400),
		"average_rating":        4.7,
		"rating_distribution":   []any{float64(0), float64(1), float64(1), float64(3), float64(6)},
		"standing": map[string]any{
			"settled_trips":                          float64(12),
			"driver_fault_cancellations":             float64(1),
			"passenger_fault_cancellations":          float64(2),
			"system_fault_cancellations":             float64(1),
			"no_fault_cancellations":                 float64(1),
			"safety_related_cancellations":           float64(1),
			"pending_review_cancellations":           float64(1),
			"admin_override_cancellations":           float64(0),
			"completion_rate_percent":                91.6,
			"driver_fault_cancellation_rate_percent": 8.3,
		},
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("stats response = %#v, want %#v", got, want)
	}
}

func TestNewDriverEarningsResponsePreservesPeriodAndBucketFields(t *testing.T) {
	summary := domain.DriverEarningsSummary{
		Timezone:  "Asia/Manila",
		Today:     domain.EarningsPeriod{EarningsAmount: 1200, CompletedTrips: 2},
		ThisWeek:  domain.EarningsPeriod{EarningsAmount: 4000, CompletedTrips: 7},
		ThisMonth: domain.EarningsPeriod{EarningsAmount: 8000, CompletedTrips: 13},
		Weekdays: []domain.EarningsBucket{
			{StartDate: "2026-10-12", EarningsAmount: 1200, CompletedTrips: 2},
		},
		MonthWeeks: []domain.EarningsBucket{
			{StartDate: "2026-10-01", EarningsAmount: 8000, CompletedTrips: 13},
		},
	}

	got := marshalResponseMap(t, NewDriverEarningsResponse(summary))
	want := map[string]any{
		"timezone":   "Asia/Manila",
		"today":      map[string]any{"earnings_amount": float64(1200), "completed_trips": float64(2)},
		"this_week":  map[string]any{"earnings_amount": float64(4000), "completed_trips": float64(7)},
		"this_month": map[string]any{"earnings_amount": float64(8000), "completed_trips": float64(13)},
		"weekdays": []any{
			map[string]any{
				"start_date":      "2026-10-12",
				"earnings_amount": float64(1200),
				"completed_trips": float64(2),
			},
		},
		"month_weeks": []any{
			map[string]any{
				"start_date":      "2026-10-01",
				"earnings_amount": float64(8000),
				"completed_trips": float64(13),
			},
		},
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("earnings response = %#v, want %#v", got, want)
	}
}

func TestNewPassengerActivitySummaryResponsePreservesWireFields(t *testing.T) {
	got := marshalResponseMap(t, NewPassengerActivitySummaryResponse(domain.PassengerActivitySummary{
		ThisWeekFareAmount:     2817,
		ThisWeekCompletedRides: 1,
	}))
	want := map[string]any{
		"this_week_fare_amount":     float64(2817),
		"this_week_completed_rides": float64(1),
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("activity response = %#v, want %#v", got, want)
	}
}

func marshalResponseMap(t *testing.T, value any) map[string]any {
	t.Helper()
	encoded, err := json.Marshal(value)
	if err != nil {
		t.Fatalf("marshal response: %v", err)
	}
	var response map[string]any
	if err := json.Unmarshal(encoded, &response); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	return response
}

package domain

import "testing"

func TestBuildDriverStandingCalculatesRatesWithoutPunishingNonFaultOutcomes(t *testing.T) {
	standing, err := BuildDriverStanding(10, 8, 1, 2, 1, 1, 1, 1, 0)
	if err != nil {
		t.Fatalf("BuildDriverStanding() error = %v", err)
	}
	if standing.CompletionRatePercent != 80 {
		t.Fatalf("completion rate = %v, want 80", standing.CompletionRatePercent)
	}
	if standing.DriverFaultCancellationRatePercent != 10 {
		t.Fatalf("driver fault cancellation rate = %v, want 10", standing.DriverFaultCancellationRatePercent)
	}
	if standing.PassengerFaultCancellations != 2 || standing.SafetyRelatedCancellations != 1 {
		t.Fatalf("responsibility counts = %+v", standing)
	}
}

func TestBuildDriverStandingLeavesRatesEmptyBeforeTheFirstSettledTrip(t *testing.T) {
	standing, err := BuildDriverStanding(0, 0, 0, 0, 0, 0, 0, 0, 0)
	if err != nil {
		t.Fatalf("BuildDriverStanding() error = %v", err)
	}
	if standing.CompletionRatePercent != 0 || standing.DriverFaultCancellationRatePercent != 0 {
		t.Fatalf("empty standing rates = %+v", standing)
	}
}

func TestBuildDriverStandingRejectsImpossibleCounts(t *testing.T) {
	if _, err := BuildDriverStanding(1, 2, 0, 0, 0, 0, 0, 0, 0); err != ErrInvalidDriverStanding {
		t.Fatalf("error = %v, want %v", err, ErrInvalidDriverStanding)
	}
	if _, err := BuildDriverStanding(-1, 0, 0, 0, 0, 0, 0, 0, 0); err != ErrInvalidDriverStanding {
		t.Fatalf("error = %v, want %v", err, ErrInvalidDriverStanding)
	}
}

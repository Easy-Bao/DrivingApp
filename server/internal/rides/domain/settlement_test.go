package domain

import (
	"math"
	"testing"
)

func TestNewSettlementSnapshotFreezesBookingEconomics(t *testing.T) {
	snapshot, err := NewSettlementSnapshot(3200, 1500)
	if err != nil {
		t.Fatalf("NewSettlementSnapshot() error = %v", err)
	}
	if snapshot.CommissionCentavos != 480 || snapshot.DriverPayoutCentavos != 2720 {
		t.Fatalf("snapshot = %#v", snapshot)
	}
}

func TestNewSettlementSnapshotRejectsInvalidOrOverflowingTerms(t *testing.T) {
	tests := []struct {
		name string
		fare int64
		bps  int64
	}{
		{name: "zero fare", fare: 0, bps: 1500},
		{name: "negative rate", fare: 2500, bps: -1},
		{name: "rate above full fare", fare: 2500, bps: 10_001},
		{name: "multiplication overflow", fare: math.MaxInt64, bps: 10_000},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if _, err := NewSettlementSnapshot(test.fare, test.bps); err == nil {
				t.Fatal("expected invalid settlement terms to be rejected")
			}
		})
	}
}

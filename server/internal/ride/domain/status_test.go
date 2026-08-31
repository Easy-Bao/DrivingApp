package domain

import "testing"

func TestNormalizeRideStatusCanonicalizesLegacyCancellation(t *testing.T) {
	status, ok := NormalizeRideStatus(" CANCELED ")
	if !ok || status != RideCancelled {
		t.Fatalf("normalized status = %q, %t", status, ok)
	}
}

func TestRideStatusTransitionsRejectSkippingLifecycleSteps(t *testing.T) {
	valid := [][2]string{
		{string(RideRequested), string(RideAssigned)},
		{string(RideRequested), string(RideAccepted)},
		{string(RideAssigned), string(RideArrived)},
		{string(RideAccepted), string(RideArrived)},
		{string(RideArrived), string(RideInTransit)},
		{string(RideInTransit), string(RideCompleted)},
		{string(RideInTransit), "canceled"},
	}
	for _, transition := range valid {
		if !CanTransition(transition[0], transition[1]) {
			t.Fatalf("expected transition %q -> %q to be valid", transition[0], transition[1])
		}
	}
	for _, transition := range [][2]string{
		{string(RideRequested), string(RideCompleted)},
		{string(RideCompleted), string(RideCancelled)},
		{string(RideCancelled), string(RideRequested)},
		{"unknown", string(RideAccepted)},
	} {
		if CanTransition(transition[0], transition[1]) {
			t.Fatalf("expected transition %q -> %q to be rejected", transition[0], transition[1])
		}
	}
}

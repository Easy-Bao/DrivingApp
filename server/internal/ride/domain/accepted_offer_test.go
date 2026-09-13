package domain

import "testing"

func TestNewRideFromAcceptedOfferUsesAcceptedDriverFare(t *testing.T) {
	const (
		passengerFare = int64(2500)
		driverFare    = int64(3200)
	)

	ride, err := NewRideFromAcceptedOffer(
		BidSession{
			ID:                17,
			PassengerID:       7,
			OfferedFareAmount: passengerFare,
		},
		BidOffer{
			SessionID:          17,
			DriverID:           11,
			ProposedFareAmount: driverFare,
		},
		DriverAssignmentSnapshot{},
		1500,
	)
	if err != nil {
		t.Fatalf("NewRideFromAcceptedOffer() error = %v", err)
	}

	if ride.FareAmount != driverFare {
		t.Fatalf(
			"accepted ride fare = %d, want selected driver offer %d",
			ride.FareAmount,
			driverFare,
		)
	}
	if ride.CommissionBPS == nil || *ride.CommissionBPS != 1500 ||
		ride.CommissionAmount != 480 || ride.DriverPayoutAmount != 2720 {
		t.Fatalf("accepted ride settlement = %#v", ride)
	}
}

func TestNewRideFromAcceptedOfferRejectsMismatchedSession(t *testing.T) {
	_, err := NewRideFromAcceptedOffer(
		BidSession{ID: 17, PassengerID: 7},
		BidOffer{SessionID: 18, DriverID: 11, ProposedFareAmount: 3200},
		DriverAssignmentSnapshot{},
		1500,
	)
	if err == nil {
		t.Fatal("expected mismatched bid session to be rejected")
	}
}

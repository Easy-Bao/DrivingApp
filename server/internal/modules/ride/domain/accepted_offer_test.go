package domain

import (
	"errors"
	"testing"
)

func TestNewAcceptedRideSnapshotsAssignmentAndSettlement(t *testing.T) {
	driverID := 9
	ride, err := NewAcceptedRide(
		Ride{
			PassengerID:     7,
			DriverID:        &driverID,
			FareAmount:      5200,
			PickupName:      "Pickup",
			DropoffName:     "Dropoff",
			DistanceKm:      4.5,
			DurationMinutes: 16,
		},
		DriverAssignmentSnapshot{Name: "Ada", VehicleType: "sedan", PlateNumber: "ABC 123", Rating: 4.8},
		1500,
	)
	if err != nil {
		t.Fatalf("NewAcceptedRide() error = %v", err)
	}
	if ride.Status != "accepted" || ride.PassengerID != 7 || ride.DriverID == nil || *ride.DriverID != driverID {
		t.Fatalf("accepted ride identity = %+v", ride)
	}
	if ride.FareAmount != 5200 || ride.CommissionAmount != 780 || ride.DriverPayoutAmount != 4420 {
		t.Fatalf("accepted ride settlement = %+v", ride)
	}
	if ride.DriverName != "Ada" || ride.VehicleType != "sedan" || ride.PlateNumber != "ABC 123" || ride.DriverRating != 4.8 {
		t.Fatalf("accepted ride driver snapshot = %+v", ride)
	}
}

func TestNewAcceptedRideRejectsIncompleteRide(t *testing.T) {
	_, err := NewAcceptedRide(Ride{PassengerID: 7, FareAmount: 1000}, DriverAssignmentSnapshot{}, 1500)
	if !errors.Is(err, ErrInvalidTrip) {
		t.Fatalf("NewAcceptedRide() error = %v, want %v", err, ErrInvalidTrip)
	}
}

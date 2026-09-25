package lifecycle_test

import (
	"context"
	"errors"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/lifecycle"
)

type fakeLifecycleStore struct {
	ride domain.Ride
}

func (store *fakeLifecycleStore) Get(_ context.Context, _ int) (domain.Ride, error) {
	return store.ride, nil
}

func (store *fakeLifecycleStore) AcceptRide(_ context.Context, _, _ int) (domain.Ride, error) {
	return domain.Ride{}, nil
}

func (store *fakeLifecycleStore) UpdateStatus(_ context.Context, _, _ int, _, next string) (domain.Ride, error) {
	store.ride.Status = next
	return store.ride, nil
}

func TestUpdateStatusIdempotentWhenAlreadyInTargetStatus(t *testing.T) {
	driverID := 42
	store := &fakeLifecycleStore{
		ride: domain.Ride{
			ID:          1,
			PassengerID: 10,
			DriverID:    &driverID,
			Status:      string(domain.RideArrived),
		},
	}
	service := lifecycle.NewService(lifecycle.Dependencies{Store: store})

	updated, err := service.UpdateStatus(context.Background(), 1, driverID, string(domain.RideArrived))
	if err != nil {
		t.Fatalf("expected no error on duplicate status update, got %v", err)
	}
	if updated.Status != string(domain.RideArrived) {
		t.Fatalf("expected status %q, got %q", domain.RideArrived, updated.Status)
	}
}

func TestUpdateStatusValidTransition(t *testing.T) {
	driverID := 42
	store := &fakeLifecycleStore{
		ride: domain.Ride{
			ID:          1,
			PassengerID: 10,
			DriverID:    &driverID,
			Status:      string(domain.RideAccepted),
		},
	}
	service := lifecycle.NewService(lifecycle.Dependencies{Store: store})

	updated, err := service.UpdateStatus(context.Background(), 1, driverID, string(domain.RideArrived))
	if err != nil {
		t.Fatalf("expected no error on valid transition, got %v", err)
	}
	if updated.Status != string(domain.RideArrived) {
		t.Fatalf("expected status %q, got %q", domain.RideArrived, updated.Status)
	}
}

func TestUpdateStatusRejectsInvalidTransition(t *testing.T) {
	driverID := 42
	store := &fakeLifecycleStore{
		ride: domain.Ride{
			ID:          1,
			PassengerID: 10,
			DriverID:    &driverID,
			Status:      string(domain.RideRequested),
		},
	}
	service := lifecycle.NewService(lifecycle.Dependencies{Store: store})

	_, err := service.UpdateStatus(context.Background(), 1, driverID, string(domain.RideCompleted))
	if !errors.Is(err, domain.ErrInvalidStatusTransition) {
		t.Fatalf("expected ErrInvalidStatusTransition, got %v", err)
	}
}

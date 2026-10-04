package lifecycle_test

import (
	"context"
	"errors"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/lifecycle"
)

type fakeLifecycleStore struct {
	ride       domain.Ride
	transition domain.RideTransition
}

func (store *fakeLifecycleStore) Get(_ context.Context, _ int) (domain.Ride, error) {
	return store.ride, nil
}

func (store *fakeLifecycleStore) AcceptRide(_ context.Context, _, _ int) (domain.Ride, error) {
	return domain.Ride{}, nil
}

func (store *fakeLifecycleStore) UpdateStatus(
	_ context.Context,
	_, _ int,
	_, next string,
	transition domain.RideTransition,
) (domain.Ride, error) {
	store.transition = transition
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

func TestUpdateStatusRequiresCancellationCommand(t *testing.T) {
	store := &fakeLifecycleStore{
		ride: domain.Ride{
			ID:          1,
			PassengerID: 10,
			Status:      string(domain.RideAccepted),
		},
	}
	service := lifecycle.NewService(lifecycle.Dependencies{Store: store})

	_, err := service.UpdateStatus(context.Background(), 1, 10, string(domain.RideCancelled))
	if !errors.Is(err, domain.ErrCancellationCommand) {
		t.Fatalf("expected cancellation command error, got %v", err)
	}
}

func TestCancelDerivesDriverResponsibilityFromPassengerReason(t *testing.T) {
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

	updated, err := service.Cancel(context.Background(), domain.CancellationRequest{
		RideID:  1,
		ActorID: 10,
		Reason:  domain.CancellationReasonDriverNoShow,
	})
	if err != nil {
		t.Fatalf("Cancel() error = %v", err)
	}
	if updated.Status != string(domain.RideCancelled) {
		t.Fatalf("status = %q, want cancelled", updated.Status)
	}
	if store.transition.Reason != domain.CancellationReasonDriverNoShow {
		t.Fatalf("reason = %q, want %q", store.transition.Reason, domain.CancellationReasonDriverNoShow)
	}
	if store.transition.Responsibility != domain.CancellationResponsibilityDriverFault {
		t.Fatalf("responsibility = %q, want %q", store.transition.Responsibility, domain.CancellationResponsibilityDriverFault)
	}
}

func TestCancelRejectsReasonFromWrongActor(t *testing.T) {
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

	_, err := service.Cancel(context.Background(), domain.CancellationRequest{
		RideID:  1,
		ActorID: driverID,
		Reason:  domain.CancellationReasonDriverNoShow,
	})
	if !errors.Is(err, domain.ErrInvalidCancellation) {
		t.Fatalf("expected invalid cancellation, got %v", err)
	}
}

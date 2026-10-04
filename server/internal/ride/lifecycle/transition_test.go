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

func (store *fakeLifecycleStore) MarkArrived(
	_ context.Context,
	_, _ int,
	_ string,
) (domain.Ride, error) {
	store.ride.Status = string(domain.RideArrived)
	return store.ride, nil
}

func (store *fakeLifecycleStore) MarkPassengerNoShow(
	_ context.Context,
	_, _ int,
) (domain.Ride, error) {
	store.ride.Status = string(domain.RideCancelled)
	return store.ride, nil
}

func (store *fakeLifecycleStore) StartTrip(
	_ context.Context,
	_, _ int,
) (domain.Ride, error) {
	store.ride.Status = string(domain.RideInTransit)
	return store.ride, nil
}

func (store *fakeLifecycleStore) CompleteTrip(
	_ context.Context,
	_, _ int,
) (domain.Ride, error) {
	store.ride.Status = string(domain.RideCompleted)
	return store.ride, nil
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
			Status:      string(domain.RideInTransit),
		},
	}
	service := lifecycle.NewService(lifecycle.Dependencies{Store: store})

	updated, err := service.UpdateStatus(context.Background(), 1, driverID, string(domain.RideInTransit))
	if err != nil {
		t.Fatalf("expected no error on duplicate status update, got %v", err)
	}
	if updated.Status != string(domain.RideInTransit) {
		t.Fatalf("expected status %q, got %q", domain.RideInTransit, updated.Status)
	}
}

func TestStartTripRequiresPickupProximity(t *testing.T) {
	driverID := 42
	store := &fakeLifecycleStore{
		ride: domain.Ride{
			ID:              1,
			PassengerID:     10,
			DriverID:        &driverID,
			Status:          string(domain.RideArrived),
			PickupLatitude:  6.7000,
			PickupLongitude: 122.1000,
		},
	}
	service := lifecycle.NewService(lifecycle.Dependencies{Store: store})

	updated, err := service.StartTrip(context.Background(), 1, driverID, 6.7005, 122.1005)
	if err != nil {
		t.Fatalf("StartTrip() error = %v", err)
	}
	if updated.Status != string(domain.RideInTransit) {
		t.Fatalf("expected status %q, got %q", domain.RideInTransit, updated.Status)
	}
}

func TestStartTripIsIdempotentAfterTheServerAlreadyStartedIt(t *testing.T) {
	driverID := 42
	store := &fakeLifecycleStore{
		ride: domain.Ride{
			ID:          1,
			PassengerID: 10,
			DriverID:    &driverID,
			Status:      string(domain.RideInTransit),
		},
	}
	service := lifecycle.NewService(lifecycle.Dependencies{Store: store})

	updated, err := service.StartTrip(context.Background(), 1, driverID, 0, 0)
	if err != nil {
		t.Fatalf("StartTrip() retry error = %v", err)
	}
	if updated.Status != string(domain.RideInTransit) {
		t.Fatalf("status = %q, want in_transit", updated.Status)
	}
}

func TestCompleteTripRequiresDestinationProximity(t *testing.T) {
	driverID := 42
	store := &fakeLifecycleStore{
		ride: domain.Ride{
			ID:               1,
			PassengerID:      10,
			DriverID:         &driverID,
			Status:           string(domain.RideInTransit),
			DropoffLatitude:  6.7000,
			DropoffLongitude: 122.1000,
		},
	}
	service := lifecycle.NewService(lifecycle.Dependencies{Store: store})

	if _, err := service.CompleteTrip(context.Background(), 1, driverID, 6.7100, 122.1100); !errors.Is(err, domain.ErrCompletionLocation) {
		t.Fatalf("expected destination proximity error, got %v", err)
	}
	if store.ride.Status != string(domain.RideInTransit) {
		t.Fatalf("ride status changed after rejected completion: %q", store.ride.Status)
	}

	updated, err := service.CompleteTrip(context.Background(), 1, driverID, 6.7005, 122.1005)
	if err != nil {
		t.Fatalf("CompleteTrip() error = %v", err)
	}
	if updated.Status != string(domain.RideCompleted) {
		t.Fatalf("status = %q, want completed", updated.Status)
	}
}

func TestCompleteTripIsIdempotentAfterTheServerAlreadyCompletedIt(t *testing.T) {
	driverID := 42
	store := &fakeLifecycleStore{
		ride: domain.Ride{
			ID:          1,
			PassengerID: 10,
			DriverID:    &driverID,
			Status:      string(domain.RideCompleted),
		},
	}
	service := lifecycle.NewService(lifecycle.Dependencies{Store: store})

	updated, err := service.CompleteTrip(context.Background(), 1, driverID, 0, 0)
	if err != nil {
		t.Fatalf("CompleteTrip() retry error = %v", err)
	}
	if updated.Status != string(domain.RideCompleted) {
		t.Fatalf("status = %q, want completed", updated.Status)
	}
}

func TestMarkArrivedRequiresPickupProximity(t *testing.T) {
	driverID := 42
	store := &fakeLifecycleStore{
		ride: domain.Ride{
			ID:              1,
			PassengerID:     10,
			DriverID:        &driverID,
			Status:          string(domain.RideAccepted),
			PickupLatitude:  6.7000,
			PickupLongitude: 122.1000,
		},
	}
	service := lifecycle.NewService(lifecycle.Dependencies{Store: store})

	if _, err := service.MarkArrived(context.Background(), 1, driverID, 6.7100, 122.1100); !errors.Is(err, domain.ErrArrivalLocation) {
		t.Fatalf("expected pickup proximity error, got %v", err)
	}
	if store.ride.Status != string(domain.RideAccepted) {
		t.Fatalf("ride status changed after rejected arrival: %q", store.ride.Status)
	}
}

func TestMarkArrivedPersistsOnlyForTheAssignedDriver(t *testing.T) {
	driverID := 42
	store := &fakeLifecycleStore{
		ride: domain.Ride{
			ID:              1,
			PassengerID:     10,
			DriverID:        &driverID,
			Status:          string(domain.RideAccepted),
			PickupLatitude:  6.7000,
			PickupLongitude: 122.1000,
		},
	}
	service := lifecycle.NewService(lifecycle.Dependencies{Store: store})

	updated, err := service.MarkArrived(context.Background(), 1, driverID, 6.7005, 122.1005)
	if err != nil {
		t.Fatalf("MarkArrived() error = %v", err)
	}
	if updated.Status != string(domain.RideArrived) {
		t.Fatalf("status = %q, want arrived", updated.Status)
	}
}

func TestUpdateStatusRejectsTripCompletionCommand(t *testing.T) {
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
	if !errors.Is(err, domain.ErrTripCompletionCommand) {
		t.Fatalf("expected ErrTripCompletionCommand, got %v", err)
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

func TestCancelIsIdempotentForTheSameActorAndCancellationDetails(t *testing.T) {
	driverID := 42
	cancelledBy := 10
	store := &fakeLifecycleStore{
		ride: domain.Ride{
			ID:                         1,
			PassengerID:                10,
			DriverID:                   &driverID,
			Status:                     string(domain.RideCancelled),
			CancelledBy:                &cancelledBy,
			CancellationReason:         string(domain.CancellationReasonDriverNoShow),
			CancellationDetails:        "Driver did not move toward pickup.",
			CancellationResponsibility: string(domain.CancellationResponsibilityDriverFault),
		},
	}
	service := lifecycle.NewService(lifecycle.Dependencies{Store: store})

	updated, err := service.Cancel(context.Background(), domain.CancellationRequest{
		RideID:  1,
		ActorID: 10,
		Reason:  domain.CancellationReasonDriverNoShow,
		Details: "Driver did not move toward pickup.",
	})
	if err != nil {
		t.Fatalf("Cancel() retry error = %v", err)
	}
	if updated.Status != string(domain.RideCancelled) {
		t.Fatalf("status = %q, want cancelled", updated.Status)
	}
	if store.transition.EventType != "" {
		t.Fatalf("idempotent retry wrote a transition: %+v", store.transition)
	}
}

func TestCancelRejectsDifferentRetryForAnAlreadyCancelledRide(t *testing.T) {
	driverID := 42
	cancelledBy := 10
	store := &fakeLifecycleStore{
		ride: domain.Ride{
			ID:                 1,
			PassengerID:        10,
			DriverID:           &driverID,
			Status:             string(domain.RideCancelled),
			CancelledBy:        &cancelledBy,
			CancellationReason: string(domain.CancellationReasonDriverNoShow),
		},
	}
	service := lifecycle.NewService(lifecycle.Dependencies{Store: store})

	_, err := service.Cancel(context.Background(), domain.CancellationRequest{
		RideID:  1,
		ActorID: 10,
		Reason:  domain.CancellationReasonPassengerChangedMind,
	})
	if !errors.Is(err, domain.ErrInvalidStatusTransition) {
		t.Fatalf("expected invalid status transition, got %v", err)
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

func TestEmergencyStopUsesSafetyAttributionAfterTripStart(t *testing.T) {
	driverID := 42
	store := &fakeLifecycleStore{
		ride: domain.Ride{
			ID:          1,
			PassengerID: 10,
			DriverID:    &driverID,
			Status:      string(domain.RideInTransit),
		},
	}
	service := lifecycle.NewService(lifecycle.Dependencies{Store: store})

	updated, err := service.EmergencyStop(context.Background(), domain.EmergencyStopRequest{
		RideID:  1,
		ActorID: driverID,
		Reason:  domain.EmergencyStopReasonAccident,
		Details: "Minor collision; passenger is safe.",
	})
	if err != nil {
		t.Fatalf("EmergencyStop() error = %v", err)
	}
	if updated.Status != string(domain.RideCancelled) {
		t.Fatalf("status = %q, want cancelled", updated.Status)
	}
	if store.transition.EventType != domain.RideEventEmergencyStopped {
		t.Fatalf("event type = %q, want %q", store.transition.EventType, domain.RideEventEmergencyStopped)
	}
	if store.transition.Reason != domain.CancellationReason(domain.EmergencyStopReasonAccident) {
		t.Fatalf("reason = %q, want %q", store.transition.Reason, domain.EmergencyStopReasonAccident)
	}
	if store.transition.Responsibility != domain.CancellationResponsibilitySafetyRelated {
		t.Fatalf("responsibility = %q, want %q", store.transition.Responsibility, domain.CancellationResponsibilitySafetyRelated)
	}
}

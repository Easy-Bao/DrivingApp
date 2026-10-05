package lifecycle_test

import (
	"context"
	"errors"
	"testing"
	"time"

	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/lifecycle"
)

type fakeLifecycleStore struct {
	ride                  domain.Ride
	transition            domain.RideTransition
	arrivalCalls          int
	noShowCalls           int
	acceptCalls           int
	passengerWaitDuration time.Duration
}

func (store *fakeLifecycleStore) Get(_ context.Context, _ int) (domain.Ride, error) {
	return store.ride, nil
}

func (store *fakeLifecycleStore) AcceptRide(_ context.Context, _, _ int) (domain.Ride, error) {
	store.acceptCalls++
	store.ride.Status = string(domain.RideAccepted)
	return store.ride, nil
}

func (store *fakeLifecycleStore) MarkArrived(
	_ context.Context,
	_, _ int,
	_ string,
	passengerWaitDuration time.Duration,
) (domain.Ride, error) {
	store.arrivalCalls++
	store.passengerWaitDuration = passengerWaitDuration
	store.ride.Status = string(domain.RideArrived)
	return store.ride, nil
}

func (store *fakeLifecycleStore) MarkPassengerNoShow(
	_ context.Context,
	_, _ int,
) (domain.Ride, error) {
	store.noShowCalls++
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

func TestAcceptRideIsIdempotentForTheSameDriverWithAnActiveRide(t *testing.T) {
	driverID := 42
	store := &fakeLifecycleStore{
		ride: domain.Ride{
			ID:          1,
			PassengerID: 10,
			DriverID:    &driverID,
			Status:      string(domain.RideAccepted),
		},
	}
	published := 0
	service := lifecycle.NewService(lifecycle.Dependencies{
		Store: store,
		PublishRide: func(
			context.Context,
			event.Type,
			domain.Ride,
			map[string]any,
		) {
			published++
		},
	})

	accepted, err := service.AcceptRide(context.Background(), 1, driverID)
	if err != nil {
		t.Fatalf("AcceptRide() retry error = %v", err)
	}
	if accepted.Status != string(domain.RideAccepted) {
		t.Fatalf("status = %q, want accepted", accepted.Status)
	}
	if store.acceptCalls != 0 {
		t.Fatalf("idempotent retry called the acceptance store %d times", store.acceptCalls)
	}
	if published != 0 {
		t.Fatalf("idempotent retry published %d match events", published)
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

func TestStartTripUsesConfiguredArrivalRadius(t *testing.T) {
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
	service := lifecycle.NewService(lifecycle.Dependencies{
		Store:  store,
		Config: lifecycle.Config{ArrivalRadiusMeters: 25},
	})

	_, err := service.StartTrip(context.Background(), 1, driverID, 6.7005, 122.1005)
	if !errors.Is(err, domain.ErrArrivalLocation) {
		t.Fatalf("expected configured pickup proximity error, got %v", err)
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

func TestCompleteTripUsesConfiguredDestinationRadius(t *testing.T) {
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
	service := lifecycle.NewService(lifecycle.Dependencies{
		Store:  store,
		Config: lifecycle.Config{CompletionRadiusMeters: 25},
	})

	_, err := service.CompleteTrip(context.Background(), 1, driverID, 6.7005, 122.1005)
	if !errors.Is(err, domain.ErrCompletionLocation) {
		t.Fatalf("expected configured destination proximity error, got %v", err)
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

func TestMarkArrivedUsesConfiguredPassengerWait(t *testing.T) {
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
	service := lifecycle.NewService(lifecycle.Dependencies{
		Store:  store,
		Config: lifecycle.Config{PassengerWaitDuration: 7 * time.Minute},
	})

	if _, err := service.MarkArrived(context.Background(), 1, driverID, 6.7005, 122.1005); err != nil {
		t.Fatalf("MarkArrived() error = %v", err)
	}
	if store.passengerWaitDuration != 7*time.Minute {
		t.Fatalf("passenger wait = %v, want 7m", store.passengerWaitDuration)
	}
}

func TestMarkArrivedIsIdempotentAfterTheServerAlreadyRecordedIt(t *testing.T) {
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

	updated, err := service.MarkArrived(context.Background(), 1, driverID, 0, 0)
	if err != nil {
		t.Fatalf("MarkArrived() retry error = %v", err)
	}
	if updated.Status != string(domain.RideArrived) {
		t.Fatalf("status = %q, want arrived", updated.Status)
	}
	if store.arrivalCalls != 0 {
		t.Fatalf("idempotent retry wrote the arrival transition %d times", store.arrivalCalls)
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

func TestMarkPassengerNoShowIsIdempotentAfterTheServerAlreadyRecordedIt(t *testing.T) {
	driverID := 42
	cancelledBy := driverID
	store := &fakeLifecycleStore{
		ride: domain.Ride{
			ID:                         1,
			PassengerID:                10,
			DriverID:                   &driverID,
			Status:                     string(domain.RideCancelled),
			CancelledBy:                &cancelledBy,
			CancellationReason:         string(domain.CancellationReasonPassengerNoShow),
			CancellationResponsibility: string(domain.CancellationResponsibilityPassengerFault),
		},
	}
	service := lifecycle.NewService(lifecycle.Dependencies{Store: store})

	updated, err := service.MarkPassengerNoShow(context.Background(), 1, driverID)
	if err != nil {
		t.Fatalf("MarkPassengerNoShow() retry error = %v", err)
	}
	if updated.Status != string(domain.RideCancelled) {
		t.Fatalf("status = %q, want cancelled", updated.Status)
	}
	if store.noShowCalls != 0 {
		t.Fatalf("idempotent retry wrote the no-show transition %d times", store.noShowCalls)
	}
}

func TestMarkPassengerNoShowRejectsAnotherCancellationOutcome(t *testing.T) {
	driverID := 42
	cancelledBy := driverID
	store := &fakeLifecycleStore{
		ride: domain.Ride{
			ID:                         1,
			PassengerID:                10,
			DriverID:                   &driverID,
			Status:                     string(domain.RideCancelled),
			CancelledBy:                &cancelledBy,
			CancellationReason:         string(domain.CancellationReasonVehicleProblem),
			CancellationResponsibility: string(domain.CancellationResponsibilityDriverFault),
		},
	}
	service := lifecycle.NewService(lifecycle.Dependencies{Store: store})

	_, err := service.MarkPassengerNoShow(context.Background(), 1, driverID)
	if !errors.Is(err, domain.ErrInvalidStatusTransition) {
		t.Fatalf("expected invalid status transition, got %v", err)
	}
	if store.noShowCalls != 0 {
		t.Fatalf("rejected retry wrote the no-show transition %d times", store.noShowCalls)
	}
}

func TestMarkPassengerNoShowRequiresAValidElapsedDeadline(t *testing.T) {
	driverID := 42
	futureDeadline := time.Now().UTC().Add(time.Minute).Format(time.RFC3339)
	invalidDeadline := "not-a-deadline"
	tests := []struct {
		name         string
		waitingUntil *string
	}{
		{name: "missing deadline", waitingUntil: nil},
		{name: "malformed deadline", waitingUntil: &invalidDeadline},
		{name: "deadline has not elapsed", waitingUntil: &futureDeadline},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			store := &fakeLifecycleStore{
				ride: domain.Ride{
					ID:           1,
					PassengerID:  10,
					DriverID:     &driverID,
					Status:       string(domain.RideArrived),
					WaitingUntil: test.waitingUntil,
				},
			}
			service := lifecycle.NewService(lifecycle.Dependencies{Store: store})

			_, err := service.MarkPassengerNoShow(context.Background(), 1, driverID)
			if !errors.Is(err, domain.ErrPassengerNoShowNotReady) {
				t.Fatalf("expected passenger no-show not ready, got %v", err)
			}
			if store.noShowCalls != 0 {
				t.Fatalf("rejected no-show wrote the transition %d times", store.noShowCalls)
			}
		})
	}
}

func TestMarkPassengerNoShowPersistsAfterTheDeadline(t *testing.T) {
	driverID := 42
	pastDeadline := time.Now().UTC().Add(-time.Minute).Format(time.RFC3339)
	store := &fakeLifecycleStore{
		ride: domain.Ride{
			ID:           1,
			PassengerID:  10,
			DriverID:     &driverID,
			Status:       string(domain.RideArrived),
			WaitingUntil: &pastDeadline,
		},
	}
	service := lifecycle.NewService(lifecycle.Dependencies{Store: store})

	updated, err := service.MarkPassengerNoShow(context.Background(), 1, driverID)
	if err != nil {
		t.Fatalf("MarkPassengerNoShow() error = %v", err)
	}
	if updated.Status != string(domain.RideCancelled) {
		t.Fatalf("status = %q, want cancelled", updated.Status)
	}
	if store.noShowCalls != 1 {
		t.Fatalf("no-show transition writes = %d, want 1", store.noShowCalls)
	}
}

func TestCancelDefersUnverifiedDriverFaultClaim(t *testing.T) {
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
	if store.transition.Responsibility != domain.CancellationResponsibilityPendingReview {
		t.Fatalf("responsibility = %q, want %q", store.transition.Responsibility, domain.CancellationResponsibilityPendingReview)
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

package app_test

import (
	"context"
	"errors"
	"math"
	"testing"
	"time"

	lifecycle "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
)

// Challenger Test Suite for StartTrip proximity and dwell guards
func TestChallengerStartTrip_BoundaryConditions(t *testing.T) {
	driverID := 42
	const radiusMeters = 100.0
	const earthRadius = 6_371_000.0

	// 1 radian of latitude is earthRadius meters
	justInsideDeltaDeg := ((radiusMeters - 0.05) / earthRadius) * (180.0 / math.Pi)
	justOutsideDeltaDeg := ((radiusMeters + 0.05) / earthRadius) * (180.0 / math.Pi)

	tenSecAgo := time.Now().UTC().Add(-10 * time.Second).Format(time.RFC3339)

	t.Run("Zero distance (exact pickup location)", func(t *testing.T) {
		store := &fakeLifecycleStore{
			ride: domain.Ride{
				ID:              1,
				PassengerID:     10,
				DriverID:        &driverID,
				Status:          string(domain.RideArrived),
				PickupLatitude:  14.5995,
				PickupLongitude: 120.9842,
				ArrivedAt:       &tenSecAgo,
			},
		}
		svc, _ := newLifecycleServiceWithLocation(store, lifecycle.LifecycleConfig{ArrivalRadiusMeters: radiusMeters}, 14.5995, 120.9842)
		updated, err := svc.StartTrip(context.Background(), 1, driverID, 14.5995, 120.9842)
		if err != nil {
			t.Fatalf("unexpected error at zero distance: %v", err)
		}
		if updated.Status != string(domain.RideInTransit) {
			t.Fatalf("expected in_transit, got %s", updated.Status)
		}
	})

	t.Run("Boundary: Just inside arrival radius", func(t *testing.T) {
		driverLat := 14.5995 + justInsideDeltaDeg
		driverLng := 120.9842
		store := &fakeLifecycleStore{
			ride: domain.Ride{
				ID:              1,
				PassengerID:     10,
				DriverID:        &driverID,
				Status:          string(domain.RideArrived),
				PickupLatitude:  14.5995,
				PickupLongitude: 120.9842,
				ArrivedAt:       &tenSecAgo,
			},
		}
		svc, _ := newLifecycleServiceWithLocation(store, lifecycle.LifecycleConfig{ArrivalRadiusMeters: radiusMeters}, driverLat, driverLng)
		updated, err := svc.StartTrip(context.Background(), 1, driverID, driverLat, driverLng)
		if err != nil {
			t.Fatalf("unexpected error just inside radius: %v", err)
		}
		if updated.Status != string(domain.RideInTransit) {
			t.Fatalf("expected in_transit, got %s", updated.Status)
		}
	})

	t.Run("Boundary: Exact edge of arrival radius (within float tolerance)", func(t *testing.T) {
		// Use delta that yields distance <= radiusMeters within IEEE 754 precision
		edgeDeltaDeg := ((radiusMeters - 1e-4) / earthRadius) * (180.0 / math.Pi)
		driverLat := 14.5995 + edgeDeltaDeg
		driverLng := 120.9842
		store := &fakeLifecycleStore{
			ride: domain.Ride{
				ID:              1,
				PassengerID:     10,
				DriverID:        &driverID,
				Status:          string(domain.RideArrived),
				PickupLatitude:  14.5995,
				PickupLongitude: 120.9842,
				ArrivedAt:       &tenSecAgo,
			},
		}
		svc, _ := newLifecycleServiceWithLocation(store, lifecycle.LifecycleConfig{ArrivalRadiusMeters: radiusMeters}, driverLat, driverLng)
		updated, err := svc.StartTrip(context.Background(), 1, driverID, driverLat, driverLng)
		if err != nil {
			t.Fatalf("unexpected error at exact radius boundary: %v", err)
		}
		if updated.Status != string(domain.RideInTransit) {
			t.Fatalf("expected in_transit, got %s", updated.Status)
		}
	})

	t.Run("Boundary: Just outside arrival radius", func(t *testing.T) {
		driverLat := 14.5995 + justOutsideDeltaDeg
		driverLng := 120.9842
		store := &fakeLifecycleStore{
			ride: domain.Ride{
				ID:              1,
				PassengerID:     10,
				DriverID:        &driverID,
				Status:          string(domain.RideArrived),
				PickupLatitude:  14.5995,
				PickupLongitude: 120.9842,
				ArrivedAt:       &tenSecAgo,
			},
		}
		svc, _ := newLifecycleServiceWithLocation(store, lifecycle.LifecycleConfig{ArrivalRadiusMeters: radiusMeters}, driverLat, driverLng)
		_, err := svc.StartTrip(context.Background(), 1, driverID, driverLat, driverLng)
		if !errors.Is(err, domain.ErrArrivalLocation) {
			t.Fatalf("expected ErrArrivalLocation just outside radius, got %v", err)
		}
	})

	t.Run("Invalid coordinates (NaN, Inf, out of range)", func(t *testing.T) {
		testCases := []struct {
			name string
			lat  float64
			lng  float64
		}{
			{"NaN latitude", math.NaN(), 120.9842},
			{"NaN longitude", 14.5995, math.NaN()},
			{"Inf latitude", math.Inf(1), 120.9842},
			{"Latitude > 90", 91.0, 120.9842},
			{"Latitude < -90", -90.5, 120.9842},
			{"Longitude > 180", 14.5995, 180.1},
			{"Longitude < -180", 14.5995, -180.5},
		}
		for _, tc := range testCases {
			t.Run(tc.name, func(t *testing.T) {
				store := &fakeLifecycleStore{
					ride: domain.Ride{
						ID:              1,
						PassengerID:     10,
						DriverID:        &driverID,
						Status:          string(domain.RideArrived),
						PickupLatitude:  14.5995,
						PickupLongitude: 120.9842,
						ArrivedAt:       &tenSecAgo,
					},
				}
				svc, _ := newLifecycleServiceWithLocation(store, lifecycle.LifecycleConfig{ArrivalRadiusMeters: radiusMeters}, tc.lat, tc.lng)
				_, err := svc.StartTrip(context.Background(), 1, driverID, tc.lat, tc.lng)
				if !errors.Is(err, domain.ErrArrivalLocation) {
					t.Fatalf("expected ErrArrivalLocation for %s, got %v", tc.name, err)
				}
			})
		}
	})

	t.Run("Premature transition from invalid prior states", func(t *testing.T) {
		invalidStates := []domain.RideStatus{
			domain.RideRequested,
			domain.RideAccepted,
			domain.RideCompleted,
			domain.RideCancelled,
		}
		for _, st := range invalidStates {
			t.Run(string(st), func(t *testing.T) {
				store := &fakeLifecycleStore{
					ride: domain.Ride{
						ID:              1,
						PassengerID:     10,
						DriverID:        &driverID,
						Status:          string(st),
						PickupLatitude:  14.5995,
						PickupLongitude: 120.9842,
						ArrivedAt:       &tenSecAgo,
					},
				}
				svc, _ := newLifecycleServiceWithLocation(store, lifecycle.LifecycleConfig{ArrivalRadiusMeters: radiusMeters}, 14.5995, 120.9842)
				_, err := svc.StartTrip(context.Background(), 1, driverID, 14.5995, 120.9842)
				if !errors.Is(err, domain.ErrInvalidStatusTransition) {
					t.Fatalf("expected ErrInvalidStatusTransition from status %s, got %v", st, err)
				}
			})
		}
	})

	t.Run("Dwell guard: exact boundary tests", func(t *testing.T) {
		// Exactly 3 seconds:
		now := time.Now().UTC()
		threeSecAgo := now.Add(-3005 * time.Millisecond).Format(time.RFC3339Nano)
		store := &fakeLifecycleStore{
			ride: domain.Ride{
				ID:              1,
				PassengerID:     10,
				DriverID:        &driverID,
				Status:          string(domain.RideArrived),
				PickupLatitude:  14.5995,
				PickupLongitude: 120.9842,
				ArrivedAt:       &threeSecAgo,
			},
		}
		svc, _ := newLifecycleServiceWithLocation(store, lifecycle.LifecycleConfig{ArrivalRadiusMeters: radiusMeters}, 14.5995, 120.9842)
		updated, err := svc.StartTrip(context.Background(), 1, driverID, 14.5995, 120.9842)
		if err != nil {
			t.Fatalf("expected success when dwell >= 3s, got error: %v", err)
		}
		if updated.Status != string(domain.RideInTransit) {
			t.Fatalf("expected in_transit, got %s", updated.Status)
		}

		// Less than 3s (e.g. 1.5s ago)
		onePointFiveSecAgo := now.Add(-1500 * time.Millisecond).Format(time.RFC3339Nano)
		store.ride.ArrivedAt = &onePointFiveSecAgo
		store.ride.Status = string(domain.RideArrived)
		_, err = svc.StartTrip(context.Background(), 1, driverID, 14.5995, 120.9842)
		if !errors.Is(err, domain.ErrInvalidStatusTransition) {
			t.Fatalf("expected ErrInvalidStatusTransition when dwell < 3s, got %v", err)
		}

		// 0s ago (instant transition)
		zeroSecAgo := now.Format(time.RFC3339Nano)
		store.ride.ArrivedAt = &zeroSecAgo
		_, err = svc.StartTrip(context.Background(), 1, driverID, 14.5995, 120.9842)
		if !errors.Is(err, domain.ErrInvalidStatusTransition) {
			t.Fatalf("expected ErrInvalidStatusTransition when dwell == 0s, got %v", err)
		}

		// Future timestamp (clock skew in future)
		futureTime := now.Add(5 * time.Second).Format(time.RFC3339Nano)
		store.ride.ArrivedAt = &futureTime
		_, err = svc.StartTrip(context.Background(), 1, driverID, 14.5995, 120.9842)
		if !errors.Is(err, domain.ErrInvalidStatusTransition) {
			t.Fatalf("expected ErrInvalidStatusTransition when ArrivedAt is in future, got %v", err)
		}
	})

	t.Run("Authoritative driver location reader priority over caller coordinates", func(t *testing.T) {
		store := &fakeLifecycleStore{
			ride: domain.Ride{
				ID:              1,
				PassengerID:     10,
				DriverID:        &driverID,
				Status:          string(domain.RideArrived),
				PickupLatitude:  14.5995,
				PickupLongitude: 120.9842,
				ArrivedAt:       &tenSecAgo,
			},
		}
		// Location reader returns far location (out of radius), but caller sends near location:
		// Authoritative reader MUST take priority and reject!
		farLat := 14.5995 + justOutsideDeltaDeg
		svc := lifecycle.NewLifecycleService(lifecycle.LifecycleDependencies{
			Store: store,
			DriverLocation: &fakeDriverLocationReader{
				point: lifecycle.DriverLocation{
					Latitude:   farLat,
					Longitude:  120.9842,
					ObservedAt: time.Now().UTC(),
				},
			},
			Config: lifecycle.LifecycleConfig{ArrivalRadiusMeters: radiusMeters},
		})
		_, err := svc.StartTrip(context.Background(), 1, driverID, 14.5995, 120.9842)
		if !errors.Is(err, domain.ErrArrivalLocation) {
			t.Fatalf("expected authoritative reader location to reject spoofed client coordinates, got %v", err)
		}
	})
}

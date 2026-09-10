package booking_test

import (
	"context"
	"errors"
	"testing"

	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/application/booking"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
)

type rideWriterStub struct {
	created domain.Ride
}

func (stub *rideWriterStub) CreateRide(_ context.Context, ride domain.Ride) (domain.Ride, error) {
	stub.created = ride
	stub.created.ID = 41
	return stub.created, nil
}

func TestServiceCreateWithDetailsUsesAuthoritativeMetrics(t *testing.T) {
	writer := &rideWriterStub{}
	var published event.Type
	service := booking.NewService(booking.Dependencies{
		Writer: writer,
		ResolveRoute: func(context.Context, float64, float64, float64, float64, float64, float64) (ports.RouteMetrics, error) {
			return ports.RouteMetrics{DistanceKm: 4, DurationMinutes: 20}, nil
		},
		CalculateFare: func(distanceKm, durationMinutes float64) int64 {
			return int64(distanceKm*100 + durationMinutes*10)
		},
		PublishRide: func(_ context.Context, eventType event.Type, _ domain.Ride, _ map[string]any) {
			published = eventType
		},
	})

	ride, err := service.CreateWithDetails(context.Background(), domain.Ride{
		PassengerID:      7,
		PickupLatitude:   6.7,
		PickupLongitude:  122.1,
		DropoffLatitude:  6.71,
		DropoffLongitude: 122.11,
	})
	if err != nil {
		t.Fatalf("CreateWithDetails returned error: %v", err)
	}
	if ride.ID != 41 || ride.DistanceKm != 4 || ride.DurationMinutes != 20 || ride.FareCentavos != 600 {
		t.Fatalf("created ride = %#v", ride)
	}
	if writer.created.RideType != "solo" || writer.created.Status != string(domain.RideRequested) {
		t.Fatalf("persisted ride defaults = %#v", writer.created)
	}
	if published != event.RideOfferCreated {
		t.Fatalf("published event = %q, want %q", published, event.RideOfferCreated)
	}
}

func TestServiceEstimateFareValidatesRouteInputs(t *testing.T) {
	service := booking.NewService(booking.Dependencies{
		CalculateFare:    func(float64, float64) int64 { return 2500 },
		HasRouteProvider: true,
		ResolveRoute: func(context.Context, float64, float64, float64, float64, float64, float64) (ports.RouteMetrics, error) {
			return ports.RouteMetrics{DistanceKm: 2, DurationMinutes: 10}, nil
		},
	})

	if _, _, err := service.EstimateFare(context.Background(), nil, floatPointer(1), floatPointer(2), floatPointer(3), 0, 0); !errors.Is(err, domain.ErrInvalidTrip) {
		t.Fatalf("missing route coordinate error = %v, want invalid trip", err)
	}
	metrics, fare, err := service.EstimateFare(
		context.Background(),
		floatPointer(1),
		floatPointer(2),
		floatPointer(3),
		floatPointer(4),
		0,
		0,
	)
	if err != nil {
		t.Fatalf("EstimateFare returned error: %v", err)
	}
	if metrics.DistanceKm != 2 || metrics.DurationMinutes != 10 || fare != 2500 {
		t.Fatalf("fare result = %#v, %d", metrics, fare)
	}
}

func floatPointer(value float64) *float64 { return &value }

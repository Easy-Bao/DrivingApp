package usecase

import (
	"context"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/domain"
)

type locationRepositoryStub struct{}

func (locationRepositoryStub) Upsert(context.Context, domain.DriverPoint) error { return nil }
func (locationRepositoryStub) Remove(context.Context, string) error             { return nil }
func (locationRepositoryStub) Nearby(context.Context, float64, float64, float64) ([]domain.DriverPoint, error) {
	return nil, nil
}
func (locationRepositoryStub) Get(context.Context, string) (domain.DriverPoint, error) {
	return domain.DriverPoint{}, nil
}
func (locationRepositoryStub) UpsertPassenger(context.Context, string, domain.DriverPoint) error {
	return nil
}
func (locationRepositoryStub) GetPassenger(context.Context, string) (domain.DriverPoint, error) {
	return domain.DriverPoint{}, nil
}

func TestIngestRejectsInvalidCoordinates(t *testing.T) {
	service := NewService(locationRepositoryStub{})
	if err := service.Ingest(context.Background(), domain.DriverPoint{DriverID: "7", Latitude: 91, Longitude: 122}); err == nil {
		t.Fatal("expected invalid latitude to be rejected")
	}
	if err := service.Ingest(context.Background(), domain.DriverPoint{DriverID: "7", Latitude: 6.7, Longitude: 181}); err == nil {
		t.Fatal("expected invalid longitude to be rejected")
	}
}

func TestNearbyRejectsUnboundedRadius(t *testing.T) {
	service := NewService(locationRepositoryStub{})
	if _, err := service.Nearby(context.Background(), 6.7, 122.1, 0); err == nil {
		t.Fatal("expected zero radius to be rejected")
	}
	if _, err := service.Nearby(context.Background(), 6.7, 122.1, 51); err == nil {
		t.Fatal("expected oversized radius to be rejected")
	}
}

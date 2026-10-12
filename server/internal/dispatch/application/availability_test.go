package application_test

import (
	"context"
	"errors"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/dispatch/application"
	"github.com/Easy-Bao/DrivingApp/server/internal/dispatch/domain"
)

type driverAvailabilityReader struct {
	onlineDrivers []domain.OnlineDriver
	summaries     []domain.PublicDriverSummary
	err           error
}

func (reader *driverAvailabilityReader) OnlineDrivers(context.Context, []int) ([]domain.OnlineDriver, error) {
	return reader.onlineDrivers, reader.err
}

func (reader *driverAvailabilityReader) PublicDriverSummaries(
	context.Context,
	int,
) ([]domain.PublicDriverSummary, error) {
	return reader.summaries, reader.err
}

func TestAvailabilityServiceValidatesQueriesAndCopiesResults(t *testing.T) {
	reader := &driverAvailabilityReader{
		onlineDrivers: []domain.OnlineDriver{{ID: 7}},
		summaries:     []domain.PublicDriverSummary{{ID: 8}},
	}
	service := application.NewAvailabilityService(reader)

	if _, err := service.OnlineDrivers(context.Background(), nil); err == nil {
		t.Fatal("OnlineDrivers() accepted an empty driver id list")
	}
	if _, err := service.OnlineDrivers(context.Background(), make([]int, 21)); err == nil {
		t.Fatal("OnlineDrivers() accepted more than 20 driver ids")
	}
	if _, err := service.PublicDriverSummaries(context.Background(), 0); err == nil {
		t.Fatal("PublicDriverSummaries() accepted a nonpositive limit")
	}
	if _, err := service.PublicDriverSummaries(context.Background(), 21); err == nil {
		t.Fatal("PublicDriverSummaries() accepted a limit greater than 20")
	}

	drivers, err := service.OnlineDrivers(context.Background(), []int{7})
	if err != nil {
		t.Fatalf("OnlineDrivers() error = %v", err)
	}
	drivers[0].ID = 99
	if reader.onlineDrivers[0].ID != 7 {
		t.Fatalf("reader result was mutated through returned drivers: %#v", reader.onlineDrivers)
	}

	summaries, err := service.PublicDriverSummaries(context.Background(), 1)
	if err != nil {
		t.Fatalf("PublicDriverSummaries() error = %v", err)
	}
	summaries[0].ID = 99
	if reader.summaries[0].ID != 8 {
		t.Fatalf("reader result was mutated through returned summaries: %#v", reader.summaries)
	}
}

func TestAvailabilityServicePreservesReaderErrors(t *testing.T) {
	wantErr := errors.New("reader unavailable")
	service := application.NewAvailabilityService(&driverAvailabilityReader{err: wantErr})

	if _, err := service.OnlineDrivers(context.Background(), []int{7}); !errors.Is(err, wantErr) {
		t.Fatalf("OnlineDrivers() error = %v, want wrapped reader error", err)
	}
	if _, err := service.PublicDriverSummaries(context.Background(), 1); !errors.Is(err, wantErr) {
		t.Fatalf("PublicDriverSummaries() error = %v, want wrapped reader error", err)
	}
}

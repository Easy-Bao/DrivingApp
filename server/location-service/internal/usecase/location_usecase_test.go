package usecase

import (
	"context"
	"location-service/internal/domain"
	"testing"
)

type nearbyRepositoryStub struct {
	places []domain.Place
	calls  int
}

func (stub *nearbyRepositoryStub) SearchPlaces(context.Context, string, float64, float64) ([]domain.Place, error) {
	return nil, nil
}

func (stub *nearbyRepositoryStub) ReverseGeocode(context.Context, float64, float64) (*domain.Place, error) {
	return nil, nil
}

func (stub *nearbyRepositoryStub) GetNearbyPois(context.Context, float64, float64, int) ([]domain.Place, error) {
	stub.calls++
	return stub.places, nil
}

func (stub *nearbyRepositoryStub) GetRoute(context.Context, float64, float64, float64, float64) (*domain.Route, error) {
	return nil, nil
}

func (stub *nearbyRepositoryStub) GetTravelMatrix(context.Context, domain.Point, []domain.Point) (*domain.MatrixResult, error) {
	return nil, nil
}

func TestFilterAndPageNearbyPlaces(t *testing.T) {
	places := []domain.Place{
		{Name: "Five", DistanceKm: 5},
		{Name: "Outside", DistanceKm: 5.01},
		{Name: "One", DistanceKm: 1},
	}

	pageOne := filterAndPageNearbyPlaces(places, 1)
	if len(pageOne) != 2 {
		t.Fatalf("expected two places within 5 km, got %d", len(pageOne))
	}
	if pageOne[0].Name != "One" || pageOne[1].Name != "Five" {
		t.Fatalf("expected results sorted by distance, got %#v", pageOne)
	}

	pageTwo := filterAndPageNearbyPlaces(places, 2)
	if len(pageTwo) != 0 {
		t.Fatalf("expected no second page for two results, got %d", len(pageTwo))
	}
}

func TestFilterAndPageNearbyPlacesUsesTenItemPages(t *testing.T) {
	places := make([]domain.Place, 10)
	for index := range places {
		places[index] = domain.Place{
			Name:       "Place",
			DistanceKm: float64(index) / 4,
		}
	}

	pageOne := filterAndPageNearbyPlaces(places, 1)
	pageTwo := filterAndPageNearbyPlaces(places, 2)

	if len(pageOne) != nearbyPageSize || len(pageTwo) != 0 {
		t.Fatalf("expected 10 results on page one and none on page two, got %d and %d", len(pageOne), len(pageTwo))
	}
}

func TestSearchCacheQuerySharesAcronymVariants(t *testing.T) {
	queries := []string{"jh", "J.H", "j h"}
	for _, query := range queries {
		if got := searchCacheQuery(query); got != "jh" {
			t.Fatalf("searchCacheQuery(%q) = %q, want %q", query, got, "jh")
		}
	}
	if got := searchCacheQuery("bay plaza"); got != "bay plaza" {
		t.Fatalf("searchCacheQuery(normal query) = %q, want %q", got, "bay plaza")
	}
}

func TestNearbyPagesReuseTheUnpaginatedMemoryResult(t *testing.T) {
	places := make([]domain.Place, 20)
	for index := range places {
		places[index] = domain.Place{
			Name:       "Place",
			DistanceKm: float64(index) / 4,
		}
	}
	repository := &nearbyRepositoryStub{places: places}
	useCase := NewLocationUseCase(repository, nil, nil)

	pageOne, err := useCase.GetNearbyPois(context.Background(), 7.83, 123.44, 1)
	if err != nil {
		t.Fatal(err)
	}
	pageTwo, err := useCase.GetNearbyPois(context.Background(), 7.83, 123.44, 2)
	if err != nil {
		t.Fatal(err)
	}

	if len(pageOne) != nearbyPageSize || len(pageTwo) != nearbyPageSize {
		t.Fatalf("expected two complete nearby pages, got %d and %d", len(pageOne), len(pageTwo))
	}
	if repository.calls != 1 {
		t.Fatalf("expected one repository request, got %d", repository.calls)
	}
}

//go:build integration

package ridecontext_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"
	"time"

	ridecontext "github.com/Easy-Bao/DrivingApp/server/internal/passenger/ride_context"
	ridecontexthttp "github.com/Easy-Bao/DrivingApp/server/internal/passenger/ride_context/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

type recentDestinationReader struct {
	destinations []ridecontext.RecentDestination
	passengerID  int
	limit        int
}

func (reader *recentDestinationReader) ReadRecentDestinations(
	_ context.Context,
	passengerID, limit int,
) ([]ridecontext.RecentDestination, error) {
	reader.passengerID = passengerID
	reader.limit = limit
	return reader.destinations, nil
}

type addressResolver struct {
	address string
}

func (resolver addressResolver) ResolveAddress(
	context.Context,
	ridecontext.Coordinates,
) (string, error) {
	return resolver.address, nil
}

type coordinatedRecentDestinationReader struct {
	started chan<- struct{}
	release <-chan struct{}
}

func (reader coordinatedRecentDestinationReader) ReadRecentDestinations(
	context.Context,
	int,
	int,
) ([]ridecontext.RecentDestination, error) {
	close(reader.started)
	<-reader.release
	return []ridecontext.RecentDestination{{
		Status:   "completed",
		Title:    "Aikido of Mountain View",
		Subtitle: "Mountain View",
	}}, nil
}

type coordinatedAddressResolver struct {
	started chan<- struct{}
	release <-chan struct{}
}

func (resolver coordinatedAddressResolver) ResolveAddress(
	context.Context,
	ridecontext.Coordinates,
) (string, error) {
	close(resolver.started)
	<-resolver.release
	return "Mountain View", nil
}

type contextBoundAddressResolver struct {
	started chan<- struct{}
}

func (resolver contextBoundAddressResolver) ResolveAddress(
	ctx context.Context,
	_ ridecontext.Coordinates,
) (string, error) {
	close(resolver.started)
	<-ctx.Done()
	return "", ctx.Err()
}

func TestGuestDashboardReturnsLocationWithoutPassengerHistory(t *testing.T) {
	destinations := &recentDestinationReader{}
	router := newRouter(destinations, addressResolver{address: "Pagadian City"})

	request := httptest.NewRequest(
		http.MethodGet,
		api.V1Prefix+"/passenger/home?lat=7.8&lng=123.4",
		nil,
	)
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusOK)
	}
	var snapshot rideContextResponse
	if err := json.NewDecoder(response.Body).Decode(&snapshot); err != nil {
		t.Fatalf("decode snapshot: %v", err)
	}
	if snapshot.CurrentAddress != "Pagadian City" {
		t.Fatalf("current address = %q, want Pagadian City", snapshot.CurrentAddress)
	}
	if len(snapshot.RecentLocations) != 0 {
		t.Fatalf("guest recent locations = %#v, want empty", snapshot.RecentLocations)
	}
	if destinations.passengerID != 0 {
		t.Fatalf("guest request loaded passenger %d", destinations.passengerID)
	}
}

func TestAuthenticatedDashboardFiltersRecentDestinations(t *testing.T) {
	destinations := &recentDestinationReader{destinations: []ridecontext.RecentDestination{
		{Status: "in_transit", Title: "Active Place"},
		{Status: "completed", Title: "Mall, Pagadian City", Subtitle: "Home"},
		{Status: "completed", Title: "mall, pagadian city", Subtitle: "Office"},
		{Status: "completed", Title: "Park, Pagadian City", Subtitle: "Home"},
		{Status: "canceled", Title: "Canceled Place"},
	}}
	router := newRouter(destinations, addressResolver{})
	verifier := security.NewTokenManager("test-secret")
	accessToken, err := verifier.IssueWithRole("42", "passenger")
	if err != nil {
		t.Fatalf("issue access token: %v", err)
	}

	request := httptest.NewRequest(
		http.MethodGet,
		api.V1Prefix+"/passenger/home",
		nil,
	)
	request.Header.Set("Authorization", "Bearer "+accessToken)
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusOK)
	}
	var snapshot rideContextResponse
	if err := json.NewDecoder(response.Body).Decode(&snapshot); err != nil {
		t.Fatalf("decode snapshot: %v", err)
	}
	if destinations.passengerID != 42 || destinations.limit != 25 {
		t.Fatalf("ride query = passenger %d, limit %d; want 42, 25", destinations.passengerID, destinations.limit)
	}
	if len(snapshot.RecentLocations) != 2 {
		t.Fatalf("recent locations = %#v, want two unique completed destinations", snapshot.RecentLocations)
	}
	if snapshot.RecentLocations[0].Title != "Mall, Pagadian City" || snapshot.RecentLocations[1].Title != "Park, Pagadian City" {
		t.Fatalf("shortened destinations = %#v", snapshot.RecentLocations)
	}
}

func TestAuthenticatedDashboardLoadsLocationAndHistoryConcurrently(t *testing.T) {
	addressStarted := make(chan struct{})
	destinationsStarted := make(chan struct{})
	release := make(chan struct{})
	var releaseOnce sync.Once
	releaseAll := func() {
		releaseOnce.Do(func() { close(release) })
	}
	service := ridecontext.NewRideContextQueryService(
		coordinatedRecentDestinationReader{
			started: destinationsStarted,
			release: release,
		},
		coordinatedAddressResolver{
			started: addressStarted,
			release: release,
		},
	)

	result := make(chan struct {
		snapshot ridecontext.RideContextSnapshot
		err      error
	}, 1)
	go func() {
		snapshot, err := service.Load(
			context.Background(),
			intPointer(42),
			&ridecontext.Coordinates{Latitude: 7.8, Longitude: 123.4},
		)
		result <- struct {
			snapshot ridecontext.RideContextSnapshot
			err      error
		}{snapshot: snapshot, err: err}
	}()
	defer releaseAll()

	waitForSignal(t, addressStarted, "address resolution")
	waitForSignal(t, destinationsStarted, "recent destinations")
	releaseAll()

	select {
	case response := <-result:
		if response.err != nil {
			t.Fatalf("load ride context: %v", response.err)
		}
		if response.snapshot.CurrentAddress != "Mountain View" {
			t.Fatalf("current address = %q, want Mountain View", response.snapshot.CurrentAddress)
		}
		if len(response.snapshot.RecentLocations) != 1 {
			t.Fatalf("recent locations = %#v, want one location", response.snapshot.RecentLocations)
		}
	case <-time.After(time.Second):
		t.Fatal("ride context query did not finish after both dependencies were released")
	}
}

func TestAuthenticatedDashboardDoesNotWaitForUnboundedAddressResolution(t *testing.T) {
	addressStarted := make(chan struct{})
	service := ridecontext.NewRideContextQueryService(
		&recentDestinationReader{destinations: []ridecontext.RecentDestination{{
			Status: "completed",
			Title:  "Aikido of Mountain View",
		}}},
		contextBoundAddressResolver{started: addressStarted},
	)

	result := make(chan struct {
		snapshot ridecontext.RideContextSnapshot
		err      error
	}, 1)
	go func() {
		snapshot, err := service.Load(
			context.Background(),
			intPointer(42),
			&ridecontext.Coordinates{Latitude: 7.8, Longitude: 123.4},
		)
		result <- struct {
			snapshot ridecontext.RideContextSnapshot
			err      error
		}{snapshot: snapshot, err: err}
	}()

	waitForSignal(t, addressStarted, "bounded address resolution")
	select {
	case response := <-result:
		if response.err != nil {
			t.Fatalf("load ride context: %v", response.err)
		}
		if response.snapshot.CurrentAddress != "" {
			t.Fatalf("current address = %q, want empty after timeout", response.snapshot.CurrentAddress)
		}
		if len(response.snapshot.RecentLocations) != 1 {
			t.Fatalf("recent locations = %#v, want one location", response.snapshot.RecentLocations)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("ride context query waited for an unbounded address resolver")
	}
}

func intPointer(value int) *int {
	return &value
}

func waitForSignal(t *testing.T, signal <-chan struct{}, dependency string) {
	t.Helper()
	select {
	case <-signal:
	case <-time.After(time.Second):
		t.Fatalf("%s did not start concurrently", dependency)
	}
}

func TestDashboardRejectsInvalidOrNonPassengerAccess(t *testing.T) {
	router := newRouter(&recentDestinationReader{}, addressResolver{})
	verifier := security.NewTokenManager("test-secret")
	driverToken, err := verifier.IssueWithRole("7", "driver")
	if err != nil {
		t.Fatalf("issue driver token: %v", err)
	}

	tests := []struct {
		name   string
		setup  func(*http.Request)
		path   string
		status int
	}{
		{
			name:   "invalid coordinates",
			path:   api.V1Prefix + "/passenger/home?lat=91&lng=123",
			status: http.StatusBadRequest,
		},
		{
			name: "driver token",
			path: api.V1Prefix + "/passenger/home",
			setup: func(request *http.Request) {
				request.Header.Set("Authorization", "Bearer "+driverToken)
			},
			status: http.StatusForbidden,
		},
		{
			name: "invalid token",
			path: api.V1Prefix + "/passenger/home",
			setup: func(request *http.Request) {
				request.Header.Set("Authorization", "Bearer invalid")
			},
			status: http.StatusUnauthorized,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			request := httptest.NewRequest(http.MethodGet, test.path, nil)
			if test.setup != nil {
				test.setup(request)
			}
			response := httptest.NewRecorder()
			router.ServeHTTP(response, request)
			if response.Code != test.status {
				t.Fatalf("status = %d, want %d", response.Code, test.status)
			}
		})
	}
}

type rideContextResponse struct {
	CurrentAddress  string                   `json:"current_address"`
	RecentLocations []recentLocationResponse `json:"recent_locations"`
}

type recentLocationResponse struct {
	Title string `json:"title"`
}

func newRouter(
	destinations ridecontext.RecentDestinationReader,
	resolver ridecontext.AddressResolver,
) *chi.Mux {
	router := chi.NewRouter()
	verifier := security.NewTokenManager("test-secret")
	query := ridecontext.NewRideContextQueryService(destinations, resolver)
	ridecontexthttp.NewRouter(query, verifier).RegisterRoutes(router)
	return router
}

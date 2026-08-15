package home_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	home "github.com/Easy-Bao/DrivingApp/server/internal/passenger/home"
	homehttp "github.com/Easy-Bao/DrivingApp/server/internal/passenger/home/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/api"
	"github.com/go-chi/chi/v5"
)

type recentDestinationReader struct {
	destinations []home.RecentDestination
	passengerID  int
	limit        int
}

func (reader *recentDestinationReader) ReadRecentDestinations(
	_ context.Context,
	passengerID, limit int,
) ([]home.RecentDestination, error) {
	reader.passengerID = passengerID
	reader.limit = limit
	return reader.destinations, nil
}

type addressResolver struct {
	address string
}

func (resolver addressResolver) ResolveAddress(
	context.Context,
	home.Coordinates,
) (string, error) {
	return resolver.address, nil
}

func TestGuestHomeReturnsLocationWithoutPassengerHistory(t *testing.T) {
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
	var snapshot passengerhomeResponse
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

func TestAuthenticatedHomeFiltersRecentDestinations(t *testing.T) {
	destinations := &recentDestinationReader{destinations: []home.RecentDestination{
		{Status: "in_transit", Title: "Active Place"},
		{Status: "completed", Title: "Mall, Pagadian City", Subtitle: "Home"},
		{Status: "completed", Title: "mall, pagadian city", Subtitle: "Office"},
		{Status: "completed", Title: "Park, Pagadian City", Subtitle: "Home"},
		{Status: "canceled", Title: "Canceled Place"},
	}}
	router := newRouter(destinations, addressResolver{})
	verifier := token.NewVerifier("test-secret")
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
	var snapshot passengerhomeResponse
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

func TestHomeRejectsInvalidOrNonPassengerAccess(t *testing.T) {
	router := newRouter(&recentDestinationReader{}, addressResolver{})
	verifier := token.NewVerifier("test-secret")
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

type passengerhomeResponse struct {
	CurrentAddress  string                   `json:"current_address"`
	RecentLocations []recentLocationResponse `json:"recent_locations"`
}

type recentLocationResponse struct {
	Title string `json:"title"`
}

func newRouter(
	destinations home.RecentDestinationReader,
	resolver home.AddressResolver,
) *chi.Mux {
	router := chi.NewRouter()
	verifier := token.NewVerifier("test-secret")
	query := home.NewService(destinations, resolver)
	homehttp.NewRouter(query, verifier).RegisterRoutes(router)
	return router
}

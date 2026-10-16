package http_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	application "github.com/Easy-Bao/DrivingApp/server/internal/review/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/review/domain"
	reviewhttp "github.com/Easy-Bao/DrivingApp/server/internal/review/transport/http"
	"github.com/go-chi/chi/v5"
)

type reviewRepositoryStub struct {
	ride domain.ReviewableRide
}

func (repository reviewRepositoryStub) ReviewableRide(context.Context, int) (domain.ReviewableRide, error) {
	return repository.ride, nil
}

func (reviewRepositoryStub) DriverReviews(context.Context, int, int, int) ([]domain.Review, error) {
	return []domain.Review{{
		ID: 21, RideID: 7, DriverID: 9, PassengerID: 4,
		PassengerName: "Ada Passenger", Rating: 5,
		Comment: "Great trip", CreatedAt: "2026-10-12T14:00:00Z",
	}}, nil
}

func (reviewRepositoryStub) CreateReview(_ context.Context, review domain.Review) (domain.Review, error) {
	review.ID = 21
	review.PassengerName = "Ada Passenger"
	review.CreatedAt = "2026-10-12T14:00:00Z"
	return review, nil
}

func (reviewRepositoryStub) CreatePassengerReview(
	_ context.Context,
	review domain.PassengerReview,
) (domain.PassengerReview, error) {
	review.ID = 22
	review.CreatedAt = "2026-10-12T14:00:00Z"
	return review, nil
}

var _ application.ReviewRepository = reviewRepositoryStub{}

func TestReviewRoutesKeepPathsRolesAndResponseShapes(t *testing.T) {
	driverID := 9
	repository := reviewRepositoryStub{
		ride: domain.ReviewableRide{Status: "completed", PassengerID: 4, DriverID: &driverID},
	}
	verifier := security.NewTokenManager("review-route-test-secret")
	passengerToken, err := verifier.IssueWithRole("4", security.RolePassenger)
	if err != nil {
		t.Fatalf("issue passenger token: %v", err)
	}
	driverToken, err := verifier.IssueWithRole("9", security.RoleDriver)
	if err != nil {
		t.Fatalf("issue driver token: %v", err)
	}

	mux := chi.NewRouter()
	reviewhttp.NewRouter(reviewhttp.Dependencies{
		Service:  application.NewService(repository),
		Verifier: verifier,
	}).RegisterRoutes(mux)

	request := httptest.NewRequest(
		http.MethodPost,
		api.V1Prefix+"/drivers/9/reviews",
		strings.NewReader(`{"ride_id":7,"rating":5,"comment":"Great trip"}`),
	)
	request.Header.Set("Authorization", "Bearer "+passengerToken)
	response := httptest.NewRecorder()
	mux.ServeHTTP(response, request)
	if response.Code != http.StatusCreated {
		t.Fatalf("driver review status = %d, body = %s", response.Code, response.Body.String())
	}
	var driverReview map[string]any
	if err := json.NewDecoder(response.Body).Decode(&driverReview); err != nil {
		t.Fatalf("decode driver review: %v", err)
	}
	if driverReview["id"] != float64(21) || driverReview["ride_id"] != float64(7) ||
		driverReview["driver_id"] != float64(9) || driverReview["passenger_id"] != float64(4) ||
		driverReview["passenger_name"] != "Ada Passenger" {
		t.Fatalf("unexpected driver review response: %#v", driverReview)
	}

	request = httptest.NewRequest(http.MethodGet, api.V1Prefix+"/drivers/9/reviews", nil)
	request.Header.Set("Authorization", "Bearer "+passengerToken)
	response = httptest.NewRecorder()
	mux.ServeHTTP(response, request)
	if response.Code != http.StatusOK {
		t.Fatalf("driver reviews status = %d, body = %s", response.Code, response.Body.String())
	}
	var reviews []map[string]any
	if err := json.NewDecoder(response.Body).Decode(&reviews); err != nil {
		t.Fatalf("decode driver reviews: %v", err)
	}
	if len(reviews) != 1 || reviews[0]["id"] != float64(21) {
		t.Fatalf("unexpected driver reviews response: %#v", reviews)
	}

	request = httptest.NewRequest(
		http.MethodPost,
		api.V1Prefix+"/passengers/4/reviews",
		strings.NewReader(`{"ride_id":7,"rating":4,"comment":"Friendly passenger"}`),
	)
	request.Header.Set("Authorization", "Bearer "+driverToken)
	response = httptest.NewRecorder()
	mux.ServeHTTP(response, request)
	if response.Code != http.StatusCreated {
		t.Fatalf("passenger review status = %d, body = %s", response.Code, response.Body.String())
	}
	var passengerReview map[string]any
	if err := json.NewDecoder(response.Body).Decode(&passengerReview); err != nil {
		t.Fatalf("decode passenger review: %v", err)
	}
	if passengerReview["id"] != float64(22) || passengerReview["ride_id"] != float64(7) ||
		passengerReview["driver_id"] != float64(9) || passengerReview["passenger_id"] != float64(4) {
		t.Fatalf("unexpected passenger review response: %#v", passengerReview)
	}
}

func TestDriverCannotSubmitPassengerReview(t *testing.T) {
	driverID := 9
	verifier := security.NewTokenManager("review-route-test-secret")
	driverToken, err := verifier.IssueWithRole("9", security.RoleDriver)
	if err != nil {
		t.Fatalf("issue driver token: %v", err)
	}
	mux := chi.NewRouter()
	reviewhttp.NewRouter(reviewhttp.Dependencies{
		Service:  application.NewService(reviewRepositoryStub{ride: domain.ReviewableRide{Status: "completed", DriverID: &driverID}}),
		Verifier: verifier,
	}).RegisterRoutes(mux)
	request := httptest.NewRequest(
		http.MethodPost,
		api.V1Prefix+"/drivers/9/reviews",
		strings.NewReader(`{"ride_id":7,"rating":5}`),
	)
	request.Header.Set("Authorization", "Bearer "+driverToken)
	response := httptest.NewRecorder()
	mux.ServeHTTP(response, request)
	if response.Code != http.StatusForbidden {
		t.Fatalf("wrong-role status = %d, want %d", response.Code, http.StatusForbidden)
	}
}

//go:build integration

package ride_test

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/api"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	rideapplication "github.com/Easy-Bao/DrivingApp/server/internal/ride/application"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	ridehttp "github.com/Easy-Bao/DrivingApp/server/internal/ride/transport/http"
	"github.com/go-chi/chi/v5"
)

type failingOnlineDriversRepository struct{ analyticsRepository }

func (failingOnlineDriversRepository) OnlineDrivers(context.Context, []int) ([]domain.OnlineDriver, error) {
	return nil, errors.New("database password leaked")
}

type activeSessionsRepository struct {
	requestedDriverID  *int
	requestedSessionID int
	requestedOfferID   int
}

func (repository *activeSessionsRepository) CreateRide(context.Context, domain.Ride) (domain.Ride, error) {
	return domain.Ride{}, nil
}
func (repository *activeSessionsRepository) CreateBid(context.Context, domain.Bid) (domain.Bid, error) {
	return domain.Bid{}, nil
}
func (repository *activeSessionsRepository) AcceptBid(context.Context, int, int) (domain.Bid, domain.Ride, error) {
	return domain.Bid{}, domain.Ride{}, nil
}
func (repository *activeSessionsRepository) Get(context.Context, int) (domain.Ride, error) {
	return domain.Ride{}, nil
}
func (repository *activeSessionsRepository) CreateSession(context.Context, domain.BidSession) (domain.BidSession, error) {
	return domain.BidSession{}, nil
}
func (repository *activeSessionsRepository) ActiveSessions(_ context.Context, driverID *int) ([]domain.BidSession, error) {
	repository.requestedDriverID = driverID
	return []domain.BidSession{{ID: 101, Status: "open"}}, nil
}
func (repository *activeSessionsRepository) Offers(_ context.Context, sessionID int) ([]domain.BidOffer, error) {
	repository.requestedSessionID = sessionID
	return []domain.BidOffer{}, nil
}
func (repository *activeSessionsRepository) PlaceOffer(_ context.Context, offer domain.BidOffer) (domain.BidOffer, error) {
	repository.requestedSessionID = offer.SessionID
	return offer, nil
}
func (repository *activeSessionsRepository) AcceptOffer(_ context.Context, sessionID, offerID, passengerID int) (domain.BidSession, domain.BidOffer, domain.Ride, error) {
	repository.requestedSessionID = sessionID
	repository.requestedOfferID = offerID
	return domain.BidSession{ID: sessionID, PassengerID: passengerID}, domain.BidOffer{ID: int64(offerID), SessionID: sessionID}, domain.Ride{ID: 303, PassengerID: passengerID}, nil
}
func (repository *activeSessionsRepository) CancelSession(_ context.Context, sessionID, passengerID int) (domain.BidSession, error) {
	repository.requestedSessionID = sessionID
	return domain.BidSession{ID: sessionID, PassengerID: passengerID}, nil
}
func (repository *activeSessionsRepository) CancelOffer(_ context.Context, sessionID, driverID int) (domain.BidOffer, error) {
	repository.requestedSessionID = sessionID
	return domain.BidOffer{SessionID: sessionID, DriverID: driverID}, nil
}
func (repository *activeSessionsRepository) Session(_ context.Context, sessionID int) (domain.BidSession, error) {
	repository.requestedSessionID = sessionID
	return domain.BidSession{ID: sessionID, PassengerID: 42}, nil
}

func TestFareRoutesExposeEstimateAndFinalCalculation(t *testing.T) {
	config, err := rideapplication.LoadPricingConfig()
	if err != nil {
		t.Fatalf("LoadPricingConfig returned error: %v", err)
	}
	router := ridehttp.NewRouter(rideapplication.NewRideService(nil, config, nil), nil)
	mux := chi.NewRouter()
	router.RegisterRoutes(mux)

	test := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodGet, "/api/v1/fares/configs", nil)
	mux.ServeHTTP(test, request)
	if test.Code != http.StatusOK {
		t.Fatalf("fare config status = %d", test.Code)
	}
	var configResponse map[string]any
	if err := json.NewDecoder(test.Body).Decode(&configResponse); err != nil {
		t.Fatalf("decode fare config: %v", err)
	}
	if configResponse["serviceName"] != "Solo Ride" || configResponse["baseFare"] != float64(25) {
		t.Fatalf("unexpected fare config response: %#v", configResponse)
	}
	if _, ok := configResponse["ratingPricingConfig"].(map[string]any); !ok {
		t.Fatalf("rating pricing config is missing: %#v", configResponse)
	}

	test = httptest.NewRecorder()
	request = httptest.NewRequest(http.MethodPost, "/api/v1/fares/calculate-final", http.NoBody)
	mux.ServeHTTP(test, request)
	if test.Code != http.StatusBadRequest {
		t.Fatalf("invalid final fare status = %d", test.Code)
	}
}

func TestBookingMutationRoutesRejectTheWrongAccountRole(t *testing.T) {
	config, err := rideapplication.LoadPricingConfig()
	if err != nil {
		t.Fatal(err)
	}
	verifier := security.NewTokenManager("role-route-test-secret")
	driverToken, err := verifier.IssueWithRole("7", security.RoleDriver)
	if err != nil {
		t.Fatal(err)
	}
	passengerToken, err := verifier.IssueWithRole("8", security.RolePassenger)
	if err != nil {
		t.Fatal(err)
	}
	mux := chi.NewRouter()
	ridehttp.NewRouter(rideapplication.NewRideService(nil, config, nil), verifier).RegisterRoutes(mux)

	for _, test := range []struct {
		name   string
		path   string
		token  string
		method string
	}{
		{name: "driver cannot create passenger ride", path: api.V1Prefix + "/rides", token: driverToken, method: http.MethodPost},
		{name: "passenger cannot accept ride as driver", path: api.V1Prefix + "/rides/1/accept", token: passengerToken, method: http.MethodPost},
	} {
		t.Run(test.name, func(t *testing.T) {
			request := httptest.NewRequest(test.method, test.path, strings.NewReader(`{}`))
			request.Header.Set("Authorization", "Bearer "+test.token)
			response := httptest.NewRecorder()

			mux.ServeHTTP(response, request)

			if response.Code != http.StatusForbidden {
				t.Fatalf("status = %d, want %d", response.Code, http.StatusForbidden)
			}
		})
	}
}

func TestDriverAnalyticsAreLimitedToTheAuthenticatedDriver(t *testing.T) {
	config, err := rideapplication.LoadPricingConfig()
	if err != nil {
		t.Fatalf("LoadPricingConfig returned error: %v", err)
	}
	verifier := security.NewTokenManager("test-secret")
	accessToken, err := verifier.IssueWithRole("8", security.RoleDriver)
	if err != nil {
		t.Fatalf("Issue() returned error: %v", err)
	}

	mux := chi.NewRouter()
	ridehttp.NewRouter(rideapplication.NewRideService(analyticsRepository{}, config, nil), verifier).RegisterRoutes(mux)

	request := httptest.NewRequest(http.MethodGet, api.V1Prefix+"/drivers/8/stats", nil)
	request.Header.Set("Authorization", "Bearer "+accessToken)
	response := httptest.NewRecorder()
	mux.ServeHTTP(response, request)
	if response.Code != http.StatusOK {
		t.Fatalf("stats status = %d, want %d", response.Code, http.StatusOK)
	}
	var statsResponse map[string]any
	if err := json.NewDecoder(response.Body).Decode(&statsResponse); err != nil {
		t.Fatalf("decode driver stats: %v", err)
	}
	if statsResponse["today_earnings_centavos"] != float64(2817) ||
		statsResponse["today_completed_trips"] != float64(1) {
		t.Fatalf("daily driver stats are missing: %#v", statsResponse)
	}
	for _, alias := range []string{"totalRides", "completedRides", "todayEarnings"} {
		if _, exists := statsResponse[alias]; exists {
			t.Fatalf("driver stats leaked compatibility alias %q: %#v", alias, statsResponse)
		}
	}

	request = httptest.NewRequest(http.MethodGet, api.V1Prefix+"/drivers/8/earnings", nil)
	request.Header.Set("Authorization", "Bearer "+accessToken)
	response = httptest.NewRecorder()
	mux.ServeHTTP(response, request)
	if response.Code != http.StatusOK {
		t.Fatalf("earnings status = %d, body = %s", response.Code, response.Body.String())
	}
	var earningsResponse map[string]any
	if err := json.NewDecoder(response.Body).Decode(&earningsResponse); err != nil {
		t.Fatalf("decode earnings: %v", err)
	}
	today, ok := earningsResponse["today"].(map[string]any)
	if !ok || today["earnings_centavos"] != float64(2817) || today["completed_trips"] != float64(1) {
		t.Fatalf("unexpected earnings summary: %#v", earningsResponse)
	}

	request = httptest.NewRequest(
		http.MethodGet,
		api.V1Prefix+"/drivers/8/trips?scope=active&limit=1&offset=0",
		nil,
	)
	request.Header.Set("Authorization", "Bearer "+accessToken)
	response = httptest.NewRecorder()
	mux.ServeHTTP(response, request)
	if response.Code != http.StatusOK {
		t.Fatalf("trip page status = %d, body = %s", response.Code, response.Body.String())
	}
	var tripPage struct {
		Items      []domain.Ride `json:"items"`
		HasMore    bool          `json:"has_more"`
		NextOffset *int          `json:"next_offset"`
	}
	if err := json.NewDecoder(response.Body).Decode(&tripPage); err != nil {
		t.Fatalf("decode trip page: %v", err)
	}
	if len(tripPage.Items) != 1 || tripPage.Items[0].ID != 3 || tripPage.HasMore || tripPage.NextOffset != nil {
		t.Fatalf("unexpected trip page: %#v", tripPage)
	}

	request = httptest.NewRequest(http.MethodGet, api.V1Prefix+"/drivers/9/trips", nil)
	request.Header.Set("Authorization", "Bearer "+accessToken)
	response = httptest.NewRecorder()
	mux.ServeHTTP(response, request)
	if response.Code != http.StatusForbidden {
		t.Fatalf("trips status = %d, want %d", response.Code, http.StatusForbidden)
	}
}

func TestPassengerActivitySummaryUsesAnAuthoritativeAggregate(t *testing.T) {
	config, err := rideapplication.LoadPricingConfig()
	if err != nil {
		t.Fatal(err)
	}
	verifier := security.NewTokenManager("passenger-activity-secret")
	accessToken, err := verifier.IssueWithRole("8", security.RolePassenger)
	if err != nil {
		t.Fatal(err)
	}
	mux := chi.NewRouter()
	ridehttp.NewRouter(rideapplication.NewRideService(analyticsRepository{}, config, nil), verifier).RegisterRoutes(mux)
	request := httptest.NewRequest(
		http.MethodGet,
		api.V1Prefix+"/passengers/8/activity-summary",
		nil,
	)
	request.Header.Set("Authorization", "Bearer "+accessToken)
	response := httptest.NewRecorder()

	mux.ServeHTTP(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", response.Code, response.Body.String())
	}
	var summary map[string]any
	if err := json.NewDecoder(response.Body).Decode(&summary); err != nil {
		t.Fatal(err)
	}
	if summary["this_week_fare_centavos"] != float64(2817) || summary["this_week_completed_rides"] != float64(1) {
		t.Fatalf("unexpected passenger activity summary: %#v", summary)
	}
}

func TestPublicDriverSummariesExposeRatingsWithoutSensitiveDriverData(t *testing.T) {
	config, err := rideapplication.LoadPricingConfig()
	if err != nil {
		t.Fatalf("LoadPricingConfig returned error: %v", err)
	}
	mux := chi.NewRouter()
	ridehttp.NewRouter(rideapplication.NewRideService(analyticsRepository{}, config, nil), nil).RegisterRoutes(mux)

	request := httptest.NewRequest(
		http.MethodGet,
		api.V1Prefix+"/drivers/public/summaries?limit=1",
		nil,
	)
	response := httptest.NewRecorder()
	mux.ServeHTTP(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusOK)
	}
	var summaries []map[string]any
	if err := json.NewDecoder(response.Body).Decode(&summaries); err != nil {
		t.Fatalf("decode public driver summaries: %v", err)
	}
	if len(summaries) != 1 {
		t.Fatalf("summaries = %#v, want one item", summaries)
	}
	if summaries[0]["name"] != "Ada Driver" || summaries[0]["vehicle_type"] != "Motorcycle" || summaries[0]["rating"] != 4.8 {
		t.Fatalf("unexpected public summary: %#v", summaries[0])
	}
	for _, field := range []string{"user_id", "plate_number", "onboard_passenger_count", "latitude", "longitude"} {
		if _, exists := summaries[0][field]; exists {
			t.Fatalf("public summary leaked %q: %#v", field, summaries[0])
		}
	}

	protectedRequest := httptest.NewRequest(http.MethodGet, api.V1Prefix+"/drivers/online", nil)
	protectedResponse := httptest.NewRecorder()
	mux.ServeHTTP(protectedResponse, protectedRequest)
	if protectedResponse.Code != http.StatusUnauthorized {
		t.Fatalf("protected online-driver status = %d, want %d", protectedResponse.Code, http.StatusUnauthorized)
	}
}

func TestDriverAvailabilityHidesPersistenceErrors(t *testing.T) {
	config, err := rideapplication.LoadPricingConfig()
	if err != nil {
		t.Fatalf("LoadPricingConfig returned error: %v", err)
	}
	verifier := security.NewTokenManager("test-secret")
	accessToken, err := verifier.IssueWithRole("42", security.RolePassenger)
	if err != nil {
		t.Fatalf("Issue() returned error: %v", err)
	}

	mux := chi.NewRouter()
	ridehttp.NewRouter(
		rideapplication.NewRideService(failingOnlineDriversRepository{}, config, nil),
		verifier,
	).RegisterRoutes(mux)
	request := httptest.NewRequest(http.MethodGet, api.V1Prefix+"/drivers/online?ids=7", nil)
	request.Header.Set("Authorization", "Bearer "+accessToken)
	response := httptest.NewRecorder()
	mux.ServeHTTP(response, request)

	if response.Code != http.StatusServiceUnavailable {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusServiceUnavailable)
	}
	if strings.Contains(response.Body.String(), "database password") {
		t.Fatalf("response leaked persistence details: %s", response.Body.String())
	}
}

func TestOnlineDriverReceivesPassengerBookingThroughActiveSessions(t *testing.T) {
	config, err := rideapplication.LoadPricingConfig()
	if err != nil {
		t.Fatalf("LoadPricingConfig returned error: %v", err)
	}
	repository := &activeSessionsRepository{}
	verifier := security.NewTokenManager("test-secret")
	driverToken, err := verifier.IssueWithRole("42", security.RoleDriver)
	if err != nil {
		t.Fatalf("Issue() returned error: %v", err)
	}

	mux := chi.NewRouter()
	ridehttp.NewRouter(rideapplication.NewRideService(repository, config, nil), verifier).RegisterRoutes(mux)
	request := httptest.NewRequest(http.MethodGet, api.V1Prefix+"/bids/active", nil)
	request.Header.Set("Authorization", "Bearer "+driverToken)
	response := httptest.NewRecorder()
	mux.ServeHTTP(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("active session status = %d, body = %s", response.Code, response.Body.String())
	}
	if repository.requestedDriverID == nil || *repository.requestedDriverID != 42 {
		t.Fatalf("active session driver id = %#v, want 42", repository.requestedDriverID)
	}
	var sessions []domain.BidSession
	if err := json.NewDecoder(response.Body).Decode(&sessions); err != nil {
		t.Fatalf("decode active sessions: %v", err)
	}
	if len(sessions) != 1 || sessions[0].ID != 101 {
		t.Fatalf("active sessions = %#v", sessions)
	}
}

func TestSessionRoutesBindSessionAndOfferIdentifiers(t *testing.T) {
	config, err := rideapplication.LoadPricingConfig()
	if err != nil {
		t.Fatalf("LoadPricingConfig returned error: %v", err)
	}
	repository := &activeSessionsRepository{}
	verifier := security.NewTokenManager("test-secret")
	passengerToken, err := verifier.IssueWithRole("42", security.RolePassenger)
	if err != nil {
		t.Fatalf("Issue() returned error: %v", err)
	}
	driverToken, err := verifier.IssueWithRole("42", security.RoleDriver)
	if err != nil {
		t.Fatalf("Issue() returned error: %v", err)
	}
	mux := chi.NewRouter()
	ridehttp.NewRouter(rideapplication.NewRideService(repository, config, nil), verifier).RegisterRoutes(mux)

	tests := []struct {
		name            string
		method          string
		path            string
		body            string
		role            string
		expectedStatus  int
		expectedOfferID int
	}{
		{name: "session", method: http.MethodGet, path: api.V1Prefix + "/bids/101", role: security.RolePassenger, expectedStatus: http.StatusOK},
		{name: "offers", method: http.MethodGet, path: api.V1Prefix + "/bids/101/offers", role: security.RolePassenger, expectedStatus: http.StatusOK},
		{name: "place offer", method: http.MethodPost, path: api.V1Prefix + "/bids/101/offer", body: `{"offer_price":25}`, role: security.RoleDriver, expectedStatus: http.StatusCreated},
		{name: "accept offer", method: http.MethodPost, path: api.V1Prefix + "/bids/101/offers/202/accept", body: `{}`, role: security.RolePassenger, expectedStatus: http.StatusOK, expectedOfferID: 202},
		{name: "cancel session", method: http.MethodPost, path: api.V1Prefix + "/bids/101/cancel", body: `{}`, role: security.RolePassenger, expectedStatus: http.StatusOK},
		{name: "cancel offer", method: http.MethodPost, path: api.V1Prefix + "/bids/101/cancel-offer", body: `{}`, role: security.RoleDriver, expectedStatus: http.StatusOK},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			request := httptest.NewRequest(test.method, test.path, strings.NewReader(test.body))
			accessToken := passengerToken
			if test.role == security.RoleDriver {
				accessToken = driverToken
			}
			request.Header.Set("Authorization", "Bearer "+accessToken)
			response := httptest.NewRecorder()

			mux.ServeHTTP(response, request)

			if response.Code != test.expectedStatus {
				t.Fatalf("status = %d, want %d, body = %s", response.Code, test.expectedStatus, response.Body.String())
			}
			if repository.requestedSessionID != 101 {
				t.Fatalf("session id = %d, want 101", repository.requestedSessionID)
			}
			if test.expectedOfferID != 0 && repository.requestedOfferID != test.expectedOfferID {
				t.Fatalf("offer id = %d, want %d", repository.requestedOfferID, test.expectedOfferID)
			}
		})
	}
}

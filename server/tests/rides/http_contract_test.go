package rides_test

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	"github.com/Easy-Bao/DrivingApp/server/internal/rides/domain"
	rideshttp "github.com/Easy-Bao/DrivingApp/server/internal/rides/transport/http"
	ridesusecase "github.com/Easy-Bao/DrivingApp/server/internal/rides/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/api"
	"github.com/go-chi/chi/v5"
)

type failingOnlineDriversRepository struct{ analyticsRepository }

func (failingOnlineDriversRepository) OnlineDrivers(context.Context) ([]domain.OnlineDriver, error) {
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
	config, err := ridesusecase.LoadPricingConfig()
	if err != nil {
		t.Fatalf("LoadPricingConfig returned error: %v", err)
	}
	router := rideshttp.NewRouter(ridesusecase.NewService(nil, config), nil)
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

func TestDriverAnalyticsKeepsTripsPrivateButAllowsAggregateStats(t *testing.T) {
	config, err := ridesusecase.LoadPricingConfig()
	if err != nil {
		t.Fatalf("LoadPricingConfig returned error: %v", err)
	}
	verifier := token.NewVerifier("test-secret")
	accessToken, err := verifier.Issue("7")
	if err != nil {
		t.Fatalf("Issue() returned error: %v", err)
	}

	mux := chi.NewRouter()
	rideshttp.NewRouter(ridesusecase.NewService(analyticsRepository{}, config), verifier).RegisterRoutes(mux)

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

	request = httptest.NewRequest(http.MethodGet, api.V1Prefix+"/drivers/8/trips", nil)
	request.Header.Set("Authorization", "Bearer "+accessToken)
	response = httptest.NewRecorder()
	mux.ServeHTTP(response, request)
	if response.Code != http.StatusForbidden {
		t.Fatalf("trips status = %d, want %d", response.Code, http.StatusForbidden)
	}
}

func TestPublicDriverSummariesExposeRatingsWithoutSensitiveDriverData(t *testing.T) {
	config, err := ridesusecase.LoadPricingConfig()
	if err != nil {
		t.Fatalf("LoadPricingConfig returned error: %v", err)
	}
	mux := chi.NewRouter()
	rideshttp.NewRouter(ridesusecase.NewService(analyticsRepository{}, config), nil).RegisterRoutes(mux)

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
	config, err := ridesusecase.LoadPricingConfig()
	if err != nil {
		t.Fatalf("LoadPricingConfig returned error: %v", err)
	}
	verifier := token.NewVerifier("test-secret")
	accessToken, err := verifier.Issue("42")
	if err != nil {
		t.Fatalf("Issue() returned error: %v", err)
	}

	mux := chi.NewRouter()
	rideshttp.NewRouter(
		ridesusecase.NewService(failingOnlineDriversRepository{}, config),
		verifier,
	).RegisterRoutes(mux)
	request := httptest.NewRequest(http.MethodGet, api.V1Prefix+"/drivers/online", nil)
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
	config, err := ridesusecase.LoadPricingConfig()
	if err != nil {
		t.Fatalf("LoadPricingConfig returned error: %v", err)
	}
	repository := &activeSessionsRepository{}
	verifier := token.NewVerifier("test-secret")
	driverToken, err := verifier.Issue("42")
	if err != nil {
		t.Fatalf("Issue() returned error: %v", err)
	}

	mux := chi.NewRouter()
	rideshttp.NewRouter(ridesusecase.NewService(repository, config), verifier).RegisterRoutes(mux)
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
	config, err := ridesusecase.LoadPricingConfig()
	if err != nil {
		t.Fatalf("LoadPricingConfig returned error: %v", err)
	}
	repository := &activeSessionsRepository{}
	verifier := token.NewVerifier("test-secret")
	accessToken, err := verifier.Issue("42")
	if err != nil {
		t.Fatalf("Issue() returned error: %v", err)
	}
	mux := chi.NewRouter()
	rideshttp.NewRouter(ridesusecase.NewService(repository, config), verifier).RegisterRoutes(mux)

	tests := []struct {
		name            string
		method          string
		path            string
		body            string
		expectedStatus  int
		expectedOfferID int
	}{
		{name: "session", method: http.MethodGet, path: api.V1Prefix + "/bids/101", expectedStatus: http.StatusOK},
		{name: "offers", method: http.MethodGet, path: api.V1Prefix + "/bids/101/offers", expectedStatus: http.StatusOK},
		{name: "place offer", method: http.MethodPost, path: api.V1Prefix + "/bids/101/offer", body: `{"offer_price":25}`, expectedStatus: http.StatusCreated},
		{name: "accept offer", method: http.MethodPost, path: api.V1Prefix + "/bids/101/offers/202/accept", body: `{}`, expectedStatus: http.StatusOK, expectedOfferID: 202},
		{name: "cancel session", method: http.MethodPost, path: api.V1Prefix + "/bids/101/cancel", body: `{}`, expectedStatus: http.StatusOK},
		{name: "cancel offer", method: http.MethodPost, path: api.V1Prefix + "/bids/101/cancel-offer", body: `{}`, expectedStatus: http.StatusOK},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			request := httptest.NewRequest(test.method, test.path, strings.NewReader(test.body))
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

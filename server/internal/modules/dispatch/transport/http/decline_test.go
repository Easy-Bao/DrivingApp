package http

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	dispatchapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

type declineStore struct {
	dispatchapp.BiddingStore
	actorID   int
	sessionID int
	session   domain.BidSession
	offer     domain.BidOffer
	err       error
}

func (store *declineStore) ActiveSessions(_ context.Context, _ *int) ([]domain.BidSession, error) {
	return nil, store.err
}

func (store *declineStore) Session(_ context.Context, _ int) (domain.BidSession, error) {
	return store.session, nil
}

func (store *declineStore) PlaceOffer(_ context.Context, offer domain.BidOffer) (domain.BidOffer, error) {
	store.offer = offer
	return offer, store.err
}

func (store *declineStore) DeclineSession(_ context.Context, sessionID, driverID int) (domain.BidSession, error) {
	store.actorID, store.sessionID = driverID, sessionID
	return domain.BidSession{ID: sessionID, PassengerID: 42, TargetDriverID: &driverID, Status: "declined"}, store.err
}

func TestDeclineRouteAuthorizationAndResponse(t *testing.T) {
	for _, test := range []struct {
		name    string
		role    string
		session string
		err     error
		want    int
	}{
		{name: "unauthenticated", session: "55", want: http.StatusUnauthorized},
		{name: "passenger", role: security.RolePassenger, session: "55", want: http.StatusForbidden},
		{name: "driver", role: security.RoleDriver, session: "55", want: http.StatusOK},
		{name: "invalid id", role: security.RoleDriver, session: "0", want: http.StatusBadRequest},
		{name: "wrong driver", role: security.RoleDriver, session: "55", err: domain.ErrUnauthorizedSession, want: http.StatusForbidden},
		{name: "closed", role: security.RoleDriver, session: "55", err: domain.ErrSessionClosed, want: http.StatusConflict},
		{name: "unknown", role: security.RoleDriver, session: "55", err: domain.ErrSessionNotFound, want: http.StatusNotFound},
	} {
		t.Run(test.name, func(t *testing.T) {
			store := &declineStore{err: test.err}
			verifier := security.NewTokenManager("test-secret")
			mux := chi.NewRouter()
			NewRouter(Dependencies{Service: dispatchapp.NewService(dispatchapp.Dependencies{Store: store}), Verifier: verifier}).RegisterRoutes(mux)
			request := httptest.NewRequest(http.MethodPost, "/api/v1/bids/"+test.session+"/decline", nil)
			if test.role != "" {
				token, err := verifier.IssueWithRole("201", test.role)
				if err != nil {
					t.Fatal(err)
				}
				request.Header.Set("Authorization", "Bearer "+token)
			}
			recorder := httptest.NewRecorder()
			mux.ServeHTTP(recorder, request)
			if recorder.Code != test.want {
				t.Fatalf("status = %d; body = %s", recorder.Code, recorder.Body.String())
			}
			if test.want == http.StatusOK {
				var session BidSessionResponse
				if err := json.Unmarshal(recorder.Body.Bytes(), &session); err != nil {
					t.Fatal(err)
				}
				if session.ID != 55 || session.Status != "declined" || session.TargetDriverID == nil || *session.TargetDriverID != 201 || store.actorID != 201 || store.sessionID != 55 {
					t.Fatalf("response = %+v, actor = %d", session, store.actorID)
				}
			}
		})
	}
}

func TestActiveSessionsMapsDriverUnavailableToConflict(t *testing.T) {
	store := &declineStore{err: domain.ErrDriverUnavailable}
	verifier := security.NewTokenManager("test-secret")
	mux := chi.NewRouter()
	NewRouter(Dependencies{Service: dispatchapp.NewService(dispatchapp.Dependencies{Store: store}), Verifier: verifier}).RegisterRoutes(mux)

	request := httptest.NewRequest(http.MethodGet, "/api/v1/bids/active", nil)
	token, err := verifier.IssueWithRole("201", security.RoleDriver)
	if err != nil {
		t.Fatal(err)
	}
	request.Header.Set("Authorization", "Bearer "+token)

	recorder := httptest.NewRecorder()
	mux.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusConflict {
		t.Fatalf("status = %d, want %d; body = %s", recorder.Code, http.StatusConflict, recorder.Body.String())
	}
}

func TestPlaceOfferRoundsDecimalOfferPriceAndRejectsNegativePrice(t *testing.T) {
	store := &declineStore{session: domain.BidSession{ID: 55, OfferedFareAmount: 1999}}
	verifier := security.NewTokenManager("test-secret")
	mux := chi.NewRouter()
	NewRouter(Dependencies{Service: dispatchapp.NewService(dispatchapp.Dependencies{Store: store}), Verifier: verifier}).RegisterRoutes(mux)

	token, err := verifier.IssueWithRole("201", security.RoleDriver)
	if err != nil {
		t.Fatal(err)
	}

	validRequest := httptest.NewRequest(http.MethodPost, "/api/v1/bids/55/offer", bytes.NewBufferString(`{"offer_price":19.99}`))
	validRequest.Header.Set("Authorization", "Bearer "+token)
	validRecorder := httptest.NewRecorder()
	mux.ServeHTTP(validRecorder, validRequest)
	if validRecorder.Code != http.StatusCreated {
		t.Fatalf("status = %d, want %d; body = %s", validRecorder.Code, http.StatusCreated, validRecorder.Body.String())
	}
	if store.offer.ProposedFareAmount != 1999 {
		t.Fatalf("ProposedFareAmount = %d, want 1999", store.offer.ProposedFareAmount)
	}

	negativeRequest := httptest.NewRequest(http.MethodPost, "/api/v1/bids/55/offer", bytes.NewBufferString(`{"offer_price":-10}`))
	negativeRequest.Header.Set("Authorization", "Bearer "+token)
	negativeRecorder := httptest.NewRecorder()
	mux.ServeHTTP(negativeRecorder, negativeRequest)
	if negativeRecorder.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d; body = %s", negativeRecorder.Code, http.StatusBadRequest, negativeRecorder.Body.String())
	}
}

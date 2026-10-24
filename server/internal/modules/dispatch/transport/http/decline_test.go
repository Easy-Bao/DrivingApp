package http

import (
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
	err       error
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

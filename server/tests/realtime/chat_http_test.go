package realtime_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/assignment"
	chatadapter "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/adapter"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/domain"
	chath "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/transport/http"
	chatusecase "github.com/Easy-Bao/DrivingApp/server/internal/realtime/chat/usecase"
	"github.com/go-chi/chi/v5"
)

type roomHistory struct {
	members map[string]bool
	locked  bool
}

func (history *roomHistory) CreateRoom(context.Context, string, string, string) error { return nil }
func (history *roomHistory) Append(context.Context, domain.Message) error             { return nil }
func (history *roomHistory) Messages(context.Context, string) ([]domain.Message, error) {
	return []domain.Message{{Body: "private"}}, nil
}
func (history *roomHistory) Resolve(context.Context, string) error { return nil }
func (history *roomHistory) RoomParticipants(context.Context, string) (string, string, error) {
	return "7", "8", nil
}
func (history *roomHistory) IsMember(_ context.Context, roomID, userID string) (bool, error) {
	return history.members[roomID+":"+userID], nil
}
func (history *roomHistory) IsLocked(context.Context, string) (bool, error) {
	return history.locked, nil
}

func TestChatHTTPRoutesRequireRoomMembership(t *testing.T) {
	tokenManager := security.NewTokenManager("chat-test-secret")
	memberToken, err := tokenManager.Issue("7")
	if err != nil {
		t.Fatal(err)
	}
	outsiderToken, err := tokenManager.Issue("8")
	if err != nil {
		t.Fatal(err)
	}
	history := &roomHistory{members: map[string]bool{"ride-1:7": true}}
	router := chi.NewRouter()
	chath.NewRouter(
		chatusecase.NewChatService(chatadapter.NewHub(), history).
			WithRideAssignmentLookup(chatAssignmentLookup{
				assignment: assignment.Assignment{
					RideID: "ride-1", PassengerID: "7", DriverID: "9", Status: "assigned",
				},
				found: true,
			}),
		tokenManager,
	).RegisterRoutes(router)

	for _, test := range []struct {
		name   string
		token  string
		status int
	}{
		{name: "missing token", status: http.StatusUnauthorized},
		{name: "outsider", token: outsiderToken, status: http.StatusForbidden},
		{name: "room member", token: memberToken, status: http.StatusOK},
	} {
		t.Run(test.name, func(t *testing.T) {
			request := httptest.NewRequest(http.MethodGet, "/api/v1/chat/rooms/ride-1/messages", nil)
			if test.token != "" {
				request.Header.Set("Authorization", "Bearer "+test.token)
			}
			response := httptest.NewRecorder()
			router.ServeHTTP(response, request)
			if response.Code != test.status {
				t.Fatalf("status = %d, want %d", response.Code, test.status)
			}
		})
	}
}

func TestChatCreateRoomReportsResolvedRoom(t *testing.T) {
	tokenManager := security.NewTokenManager("chat-test-secret")
	memberToken, err := tokenManager.Issue("7")
	if err != nil {
		t.Fatal(err)
	}
	history := &roomHistory{
		members: map[string]bool{"ride-1:7": true},
		locked:  true,
	}
	router := chi.NewRouter()
	chath.NewRouter(
		chatusecase.NewChatService(chatadapter.NewHub(), history).
			WithRideAssignmentLookup(chatAssignmentLookup{
				assignment: assignment.Assignment{
					RideID: "ride-1", PassengerID: "7", DriverID: "8", Status: "assigned",
				},
				found: true,
			}),
		tokenManager,
	).RegisterRoutes(router)

	request := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/chat/rooms",
		strings.NewReader(`{"ride_id":"ride-1"}`),
	)
	request.Header.Set("Authorization", "Bearer "+memberToken)
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)

	if response.Code != http.StatusLocked {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusLocked)
	}
}

func TestChatCreateRoomRejectsClientSuppliedParticipants(t *testing.T) {
	tokenManager := security.NewTokenManager("chat-test-secret")
	token, err := tokenManager.Issue("7")
	if err != nil {
		t.Fatal(err)
	}
	router := chi.NewRouter()
	chath.NewRouter(
		chatusecase.NewChatService(chatadapter.NewHub(), &roomHistory{}),
		tokenManager,
	).RegisterRoutes(router)

	request := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/chat/rooms",
		strings.NewReader(`{"ride_id":"ride-1","passengerId":"7","driverId":"8"}`),
	)
	request.Header.Set("Authorization", "Bearer "+token)
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)

	if response.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusBadRequest)
	}
}

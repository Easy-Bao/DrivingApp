package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/shared-core/security"
)

func TestIdentityFromRequestUsesOneBearerParsingContract(t *testing.T) {
	manager := security.NewTokenManager("auth-middleware-test-secret")
	token, err := manager.IssueWithRole("7", "driver")
	if err != nil {
		t.Fatal(err)
	}

	request := httptest.NewRequest(http.MethodGet, "/", nil)
	request.Header.Set("Authorization", "  Bearer "+token+"  ")
	identity, ok := IdentityFromRequest(request, manager)
	if !ok {
		t.Fatal("expected a valid bearer token")
	}
	if identity.Subject != "7" || identity.Role != "driver" {
		t.Fatalf("identity = %#v, want subject 7 and driver role", identity)
	}

	for _, header := range []string{"", "Basic " + token, "Bearer ", "Bearer invalid"} {
		request.Header.Set("Authorization", header)
		if _, ok := IdentityFromRequest(request, manager); ok {
			t.Fatalf("header %q was accepted", header)
		}
	}
}

func TestRequireAuthStoresTheVerifiedIdentity(t *testing.T) {
	manager := security.NewTokenManager("auth-middleware-test-secret")
	token, err := manager.IssueWithRole("9", "passenger")
	if err != nil {
		t.Fatal(err)
	}

	protected := RequireAuth(manager)(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		identity, ok := Identity(request)
		if !ok || identity.Subject != "9" || identity.Role != "passenger" {
			t.Fatalf("request identity = %#v, ok = %v", identity, ok)
		}
		writer.WriteHeader(http.StatusNoContent)
	}))
	request := httptest.NewRequest(http.MethodGet, "/", nil)
	request.Header.Set("Authorization", "Bearer "+token)
	response := httptest.NewRecorder()
	protected.ServeHTTP(response, request)
	if response.Code != http.StatusNoContent {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusNoContent)
	}
}

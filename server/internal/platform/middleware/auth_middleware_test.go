package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
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
	lowercaseScheme := httptest.NewRequest(http.MethodGet, "/", nil)
	lowercaseScheme.Header.Set("Authorization", "bearer "+token)
	if _, ok := IdentityFromRequest(lowercaseScheme, manager); !ok {
		t.Fatal("case-insensitive bearer scheme was rejected")
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

func TestRequireAuthStoresNumericPrincipalAndRoleGateRejectsWrongRole(t *testing.T) {
	manager := security.NewTokenManager("auth-middleware-test-secret")
	driverToken, err := manager.IssueWithRole("17", security.RoleDriver)
	if err != nil {
		t.Fatal(err)
	}

	protected := RequireAuth(manager)(RequireRole(security.RolePassenger)(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		principal, ok := PrincipalFromRequest(request)
		if !ok || principal.UserID != 17 {
			t.Fatalf("principal = %#v, ok = %v", principal, ok)
		}
		writer.WriteHeader(http.StatusNoContent)
	})))
	request := httptest.NewRequest(http.MethodGet, "/", nil)
	request.Header.Set("Authorization", "Bearer "+driverToken)
	response := httptest.NewRecorder()

	protected.ServeHTTP(response, request)

	if response.Code != http.StatusForbidden {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusForbidden)
	}
}

func TestRequireAuthRejectsNonNumericSubject(t *testing.T) {
	manager := security.NewTokenManager("auth-middleware-test-secret")
	token, err := manager.IssueWithRole("not-an-account", security.RolePassenger)
	if err != nil {
		t.Fatal(err)
	}
	protected := RequireAuth(manager)(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		t.Fatal("handler must not run")
	}))
	request := httptest.NewRequest(http.MethodGet, "/", nil)
	request.Header.Set("Authorization", "Bearer "+token)
	response := httptest.NewRecorder()

	protected.ServeHTTP(response, request)

	if response.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusUnauthorized)
	}
}

func TestAuthenticatedUserIDRejectsNonPositiveSubjects(t *testing.T) {
	manager := security.NewTokenManager("auth-middleware-test-secret")
	for _, subject := range []string{"0", "-1", "not-an-account"} {
		t.Run(subject, func(t *testing.T) {
			token, err := manager.IssueWithRole(subject, security.RolePassenger)
			if err != nil {
				t.Fatal(err)
			}
			request := httptest.NewRequest(http.MethodGet, "/", nil)
			request.Header.Set("Authorization", "Bearer "+token)
			if userID, ok := AuthenticatedUserID(request, manager); ok || userID != 0 {
				t.Fatalf("authenticated user id = %d, ok = %t", userID, ok)
			}
		})
	}
}

func TestRequireAdminUsesTheVerifiedPrincipalAtTheRouteBoundary(t *testing.T) {
	manager := security.NewTokenManager("admin-middleware-test-secret")
	adminToken, err := manager.IssueWithRole("42", security.RolePassenger)
	if err != nil {
		t.Fatal(err)
	}
	nonAdminToken, err := manager.IssueWithRole("7", security.RoleDriver)
	if err != nil {
		t.Fatal(err)
	}
	protected := RequireAuth(manager)(RequireAdmin(security.NewAdminAuthorizer("42"))(
		http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
			writer.WriteHeader(http.StatusNoContent)
		}),
	))

	for _, test := range []struct {
		name   string
		token  string
		status int
	}{
		{name: "missing authentication", status: http.StatusUnauthorized},
		{name: "non administrator", token: nonAdminToken, status: http.StatusForbidden},
		{name: "administrator", token: adminToken, status: http.StatusNoContent},
	} {
		t.Run(test.name, func(t *testing.T) {
			request := httptest.NewRequest(http.MethodGet, "/", nil)
			if test.token != "" {
				request.Header.Set("Authorization", "Bearer "+test.token)
			}
			response := httptest.NewRecorder()
			protected.ServeHTTP(response, request)
			if response.Code != test.status {
				t.Fatalf("status = %d, want %d", response.Code, test.status)
			}
		})
	}
}

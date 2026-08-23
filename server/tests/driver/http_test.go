package driver_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strconv"
	"strings"
	"testing"

	documenthttp "github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/transport/http"
	documentusecase "github.com/Easy-Bao/DrivingApp/server/internal/driver/documents/usecase"
	"github.com/Easy-Bao/DrivingApp/server/shared-core/security"
	"github.com/go-chi/chi/v5"
)

func TestDocumentAdministrationRequiresConfiguredAdministrator(t *testing.T) {
	tokenManager := security.NewTokenManager("document-test-secret")
	driverToken, err := tokenManager.IssueWithRole("7", security.RoleDriver)
	if err != nil {
		t.Fatal(err)
	}
	adminToken, err := tokenManager.IssueWithRole("42", security.RolePassenger)
	if err != nil {
		t.Fatal(err)
	}
	repository := newDocumentRepositoryFake()
	storage := newDocumentStorageFake()
	service := documentusecase.NewService(repository, storage, 1024)
	document, err := service.Upload(t.Context(), 7, "driver_license", "application/pdf", validPDF)
	if err != nil {
		t.Fatal(err)
	}

	router := chi.NewRouter()
	documenthttp.NewRouter(service, tokenManager, security.NewAdminAuthorizer("42")).RegisterRoutes(router)

	for _, test := range []struct {
		name   string
		token  string
		status int
	}{
		{name: "driver token", token: driverToken, status: http.StatusForbidden},
		{name: "administrator token", token: adminToken, status: http.StatusOK},
	} {
		t.Run(test.name, func(t *testing.T) {
			body, _ := json.Marshal(map[string]string{"status": "approved"})
			request := httptest.NewRequest(http.MethodPatch, "/api/v1/admin/documents/"+strconv.Itoa(document.ID)+"/review", bytes.NewReader(body))
			request.Header.Set("Authorization", "Bearer "+test.token)
			request.Header.Set("Content-Type", "application/json")
			response := httptest.NewRecorder()
			router.ServeHTTP(response, request)
			if response.Code != test.status {
				t.Fatalf("status = %d, want %d; body = %s", response.Code, test.status, response.Body.String())
			}
		})
	}
}

func TestPrivateDocumentContentIsOwnerOrAdminOnly(t *testing.T) {
	tokenManager := security.NewTokenManager("document-content-test-secret")
	ownerToken, _ := tokenManager.IssueWithRole("7", security.RoleDriver)
	otherDriverToken, _ := tokenManager.IssueWithRole("8", security.RoleDriver)
	adminToken, _ := tokenManager.IssueWithRole("42", security.RolePassenger)
	repository := newDocumentRepositoryFake()
	storage := newDocumentStorageFake()
	service := documentusecase.NewService(repository, storage, 1024)
	document, err := service.Upload(t.Context(), 7, "driver_license", "application/pdf", validPDF)
	if err != nil {
		t.Fatal(err)
	}
	router := chi.NewRouter()
	documenthttp.NewRouter(service, tokenManager, security.NewAdminAuthorizer("42")).RegisterRoutes(router)

	for _, test := range []struct {
		name   string
		path   string
		token  string
		status int
	}{
		{name: "owner", path: "/api/v1/driver/documents/" + strconv.Itoa(document.ID) + "/content", token: ownerToken, status: http.StatusOK},
		{name: "other driver", path: "/api/v1/driver/documents/" + strconv.Itoa(document.ID) + "/content", token: otherDriverToken, status: http.StatusNotFound},
		{name: "admin", path: "/api/v1/admin/documents/" + strconv.Itoa(document.ID) + "/content", token: adminToken, status: http.StatusOK},
		{name: "non admin", path: "/api/v1/admin/documents/" + strconv.Itoa(document.ID) + "/content", token: ownerToken, status: http.StatusForbidden},
	} {
		t.Run(test.name, func(t *testing.T) {
			request := httptest.NewRequest(http.MethodGet, test.path, nil)
			request.Header.Set("Authorization", "Bearer "+test.token)
			response := httptest.NewRecorder()
			router.ServeHTTP(response, request)
			if response.Code != test.status {
				t.Fatalf("status = %d, want %d; body = %s", response.Code, test.status, response.Body.String())
			}
			if test.status == http.StatusOK && response.Header().Get("Cache-Control") != "private, no-store" {
				t.Fatalf("cache control = %q", response.Header().Get("Cache-Control"))
			}
		})
	}
}

func TestDocumentUploadRequiresCanonicalTypeAndMatchingSignature(t *testing.T) {
	tokenManager := security.NewTokenManager("document-upload-test-secret")
	driverToken, _ := tokenManager.IssueWithRole("7", security.RoleDriver)
	repository := newDocumentRepositoryFake()
	storage := newDocumentStorageFake()
	router := chi.NewRouter()
	documenthttp.NewRouter(
		documentusecase.NewService(repository, storage, 1024),
		tokenManager,
		security.NewAdminAuthorizer("42"),
	).RegisterRoutes(router)

	for _, test := range []struct {
		name         string
		documentType string
		contentType  string
		status       int
	}{
		{name: "valid PDF", documentType: "driver_license", contentType: "application/pdf", status: http.StatusCreated},
		{name: "unknown document type", documentType: "license", contentType: "application/pdf", status: http.StatusUnprocessableEntity},
		{name: "mismatched signature", documentType: "driver_license", contentType: "image/png", status: http.StatusUnsupportedMediaType},
	} {
		t.Run(test.name, func(t *testing.T) {
			request := httptest.NewRequest(
				http.MethodPost,
				"/api/v1/driver/documents?type="+test.documentType,
				bytes.NewReader(validPDF),
			)
			request.Header.Set("Authorization", "Bearer "+driverToken)
			request.Header.Set("Content-Type", test.contentType)
			response := httptest.NewRecorder()
			router.ServeHTTP(response, request)
			if response.Code != test.status {
				t.Fatalf("status = %d, want %d; body = %s", response.Code, test.status, response.Body.String())
			}
			if strings.Contains(response.Body.String(), "storage_key") || strings.Contains(response.Body.String(), "checksum") {
				t.Fatalf("private metadata leaked in %s", response.Body.String())
			}
		})
	}
}

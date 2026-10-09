//go:build integration

package driver_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"sort"
	"strconv"
	"strings"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/driver/documents"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/security"
	"github.com/go-chi/chi/v5"
)

func newDocumentService(
	repository documents.DocumentStore,
	storage documents.ObjectStore,
	options ...documents.DocumentServiceOption,
) *documents.DocumentService {
	return documents.NewDocumentService(
		documents.DocumentServiceDependencies{Repository: repository, Storage: storage},
		options...,
	)
}

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
	service := newDocumentService(
		repository,
		storage,
		documents.WithContentTypeDetector(http.DetectContentType),
		documents.WithMaxDocumentBytes(1024),
	)
	document, err := service.Upload(t.Context(), 7, "driver_license", "application/pdf", validPDF)
	if err != nil {
		t.Fatal(err)
	}

	router := chi.NewRouter()
	documents.NewRouter(documents.RouterDependencies{
		Service:    service,
		Verifier:   tokenManager,
		Authorizer: security.NewAdminAuthorizer("42"),
	}).RegisterRoutes(router)

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
			request := httptest.NewRequest(
				http.MethodPatch,
				"/api/v1/admin/documents/"+strconv.Itoa(document.ID)+"/review",
				bytes.NewReader(body),
			)
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
	service := newDocumentService(
		repository,
		storage,
		documents.WithContentTypeDetector(http.DetectContentType),
		documents.WithMaxDocumentBytes(1024),
	)
	document, err := service.Upload(t.Context(), 7, "driver_license", "application/pdf", validPDF)
	if err != nil {
		t.Fatal(err)
	}
	router := chi.NewRouter()
	documents.NewRouter(documents.RouterDependencies{
		Service:    service,
		Verifier:   tokenManager,
		Authorizer: security.NewAdminAuthorizer("42"),
	}).RegisterRoutes(router)

	for _, test := range []struct {
		name   string
		path   string
		token  string
		status int
	}{
		{
			name:   "owner",
			path:   "/api/v1/driver/documents/" + strconv.Itoa(document.ID) + "/content",
			token:  ownerToken,
			status: http.StatusOK,
		},
		{
			name:   "other driver",
			path:   "/api/v1/driver/documents/" + strconv.Itoa(document.ID) + "/content",
			token:  otherDriverToken,
			status: http.StatusNotFound,
		},
		{
			name:   "admin",
			path:   "/api/v1/admin/documents/" + strconv.Itoa(document.ID) + "/content",
			token:  adminToken,
			status: http.StatusOK,
		},
		{
			name:   "non admin",
			path:   "/api/v1/admin/documents/" + strconv.Itoa(document.ID) + "/content",
			token:  ownerToken,
			status: http.StatusForbidden,
		},
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
	service := newDocumentService(
		repository,
		storage,
		documents.WithContentTypeDetector(http.DetectContentType),
		documents.WithMaxDocumentBytes(1024),
	)
	router := chi.NewRouter()
	documents.NewRouter(documents.RouterDependencies{
		Service:    service,
		Verifier:   tokenManager,
		Authorizer: security.NewAdminAuthorizer("42"),
	}).RegisterRoutes(router)

	for _, test := range []struct {
		name         string
		path         string
		documentType string
		contentType  string
		status       int
		deprecated   bool
	}{
		{
			name:         "valid PDF through legacy route",
			path:         "/api/v1/driver/documents",
			documentType: "driver_license",
			contentType:  "application/pdf",
			status:       http.StatusCreated,
			deprecated:   true,
		},
		{
			name:         "valid PDF through canonical route",
			path:         "/api/v1/drivers/me/documents",
			documentType: "driver_license",
			contentType:  "application/pdf",
			status:       http.StatusCreated,
		},
		{
			name:         "unknown document type",
			path:         "/api/v1/driver/documents",
			documentType: "license",
			contentType:  "application/pdf",
			status:       http.StatusUnprocessableEntity,
			deprecated:   true,
		},
		{
			name:         "mismatched signature",
			path:         "/api/v1/driver/documents",
			documentType: "driver_license",
			contentType:  "image/png",
			status:       http.StatusUnsupportedMediaType,
			deprecated:   true,
		},
	} {
		t.Run(test.name, func(t *testing.T) {
			request := httptest.NewRequest(
				http.MethodPost,
				test.path+"?type="+test.documentType,
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
			if test.deprecated {
				if response.Header().Get("Deprecation") != "true" ||
					response.Header().Get("Link") != "</api/v1/drivers/me/documents?type="+test.documentType+">; rel=\"successor-version\"" {
					t.Fatalf("legacy route headers = %v", response.Header())
				}
			} else if response.Header().Get("Deprecation") != "" {
				t.Fatalf("canonical route has Deprecation header %q", response.Header().Get("Deprecation"))
			}
		})
	}

	document, err := service.Upload(t.Context(), 7, "driver_license", "application/pdf", validPDF)
	if err != nil {
		t.Fatal(err)
	}
	for _, test := range []struct {
		name          string
		legacyPath    string
		canonicalPath string
	}{
		{
			name:          "status",
			legacyPath:    "/api/v1/driver/documents/status",
			canonicalPath: "/api/v1/drivers/me/documents/status",
		},
		{
			name:          "content",
			legacyPath:    "/api/v1/driver/documents/" + strconv.Itoa(document.ID) + "/content",
			canonicalPath: "/api/v1/drivers/me/documents/" + strconv.Itoa(document.ID) + "/content",
		},
	} {
		t.Run(test.name+" aliases", func(t *testing.T) {
			serve := func(path string) *httptest.ResponseRecorder {
				request := httptest.NewRequest(http.MethodGet, path, nil)
				request.Header.Set("Authorization", "Bearer "+driverToken)
				response := httptest.NewRecorder()
				router.ServeHTTP(response, request)
				return response
			}
			legacy := serve(test.legacyPath)
			canonical := serve(test.canonicalPath)
			legacyBody := legacy.Body.String()
			canonicalBody := canonical.Body.String()
			if test.name == "status" {
				legacyBody = normalizeDocumentListJSON(t, legacyBody)
				canonicalBody = normalizeDocumentListJSON(t, canonicalBody)
			}
			if legacy.Code != canonical.Code || legacyBody != canonicalBody ||
				legacy.Header().Get("Content-Type") != canonical.Header().Get("Content-Type") {
				t.Fatalf("legacy response = %d %s; canonical = %d %s", legacy.Code, legacy.Body.String(), canonical.Code, canonical.Body.String())
			}
			if legacy.Header().Get("Deprecation") != "true" {
				t.Fatalf("legacy Deprecation = %q", legacy.Header().Get("Deprecation"))
			}
			if canonical.Header().Get("Deprecation") != "" {
				t.Fatalf("canonical Deprecation = %q", canonical.Header().Get("Deprecation"))
			}
			if test.name == "content" {
				wantLink := "</api/v1/drivers/me/documents/" + strconv.Itoa(document.ID) + "/content>; rel=\"successor-version\""
				if legacy.Header().Get("Link") != wantLink {
					t.Fatalf("legacy Link = %q, want %q", legacy.Header().Get("Link"), wantLink)
				}
			}
		})
	}
}

func normalizeDocumentListJSON(t *testing.T, body string) string {
	t.Helper()
	var response struct {
		Documents []json.RawMessage `json:"documents"`
	}
	if err := json.Unmarshal([]byte(body), &response); err != nil {
		t.Fatalf("decode document list: %v", err)
	}
	sort.Slice(response.Documents, func(i, j int) bool {
		var left struct {
			ID int `json:"id"`
		}
		var right struct {
			ID int `json:"id"`
		}
		if err := json.Unmarshal(response.Documents[i], &left); err != nil {
			t.Fatalf("decode document %d: %v", i, err)
		}
		if err := json.Unmarshal(response.Documents[j], &right); err != nil {
			t.Fatalf("decode document %d: %v", j, err)
		}
		return left.ID < right.ID
	})
	normalized, err := json.Marshal(response)
	if err != nil {
		t.Fatalf("encode document list: %v", err)
	}
	return string(normalized)
}

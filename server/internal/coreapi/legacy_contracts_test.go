package coreapi

import (
	"net/http"
	"testing"
)

func TestDriverRegistrationAndOperationalContracts(t *testing.T) {
	client := &handlerClient{handler: NewHandler("test-secret")}
	status, driver := requestJSON(t, client, http.MethodPost, "/api/v1/auth/driver/register", `{"email":"driver@example.test","password":"secret","name":"Driver"}`, "")
	if status != http.StatusCreated {
		t.Fatalf("driver registration status = %d", status)
	}
	token := driver["token"].(string)
	status, _ = requestJSON(t, client, http.MethodPost, "/api/v1/drivers/"+driver["user"].(map[string]any)["id"].(string)+"/online", `{"is_online":true}`, token)
	if status != http.StatusOK {
		t.Fatalf("online status = %d", status)
	}
	status, online := requestJSON(t, client, http.MethodGet, "/api/v1/drivers/online", `{}`, "")
	if status != http.StatusOK || len(online["drivers"].([]any)) != 1 {
		t.Fatalf("online drivers response = %d %#v", status, online)
	}
	status, fare := requestJSON(t, client, http.MethodPost, "/api/v1/fares/estimate", `{"distanceKm":5,"durationMinutes":10}`, "")
	if status != http.StatusOK || fare["fare_centavos"] == nil {
		t.Fatalf("fare response = %d %#v", status, fare)
	}
}

func TestProtectedContractsRejectMissingCredentials(t *testing.T) {
	client := &handlerClient{handler: NewHandler("test-secret")}
	for _, request := range []struct{ method, path string }{
		{http.MethodGet, "/api/v1/users/me"},
		{http.MethodPost, "/api/v1/rides"},
		{http.MethodPost, "/api/v1/driver/documents"},
		{http.MethodPost, "/api/v1/telemetry/location"},
	} {
		status, _ := requestJSON(t, client, request.method, request.path, `{}`, "")
		if status != http.StatusUnauthorized {
			t.Errorf("%s status = %d, want 401", request.path, status)
		}
	}
}

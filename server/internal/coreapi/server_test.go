package coreapi

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestRegisterLoginRideBidAndDocumentFlow(t *testing.T) {
	handler := NewHandler("test-secret")
	client := &handlerClient{handler: handler}

	status, registration := requestJSON(t, client, http.MethodPost, "/api/v1/auth/register", `{"email":"passenger@example.test","password":"secret","role":"passenger"}`, "")
	if status != http.StatusCreated {
		t.Fatalf("register status = %d", status)
	}
	passengerToken := registration["token"].(string)

	status, ride := requestJSON(t, client, http.MethodPost, "/api/v1/rides", `{"fare_centavos":2500}`, passengerToken)
	if status != http.StatusCreated {
		t.Fatalf("ride status = %d", status)
	}

	_, driver := requestJSON(t, client, http.MethodPost, "/api/v1/auth/register", `{"email":"driver@example.test","password":"secret","role":"driver"}`, "")
	driverToken := driver["token"].(string)
	rideID := ride["id"].(string)
	status, bid := requestJSON(t, client, http.MethodPost, "/api/v1/rides/"+rideID+"/bids", `{"fare_centavos":2400}`, driverToken)
	if status != http.StatusCreated {
		t.Fatalf("bid status = %d", status)
	}
	status, _ = requestJSON(t, client, http.MethodPost, "/api/v1/bids/"+bid["id"].(string)+"/accept", `{}`, driverToken)
	if status != http.StatusOK {
		t.Fatalf("accept status = %d", status)
	}

	status, document := requestJSON(t, client, http.MethodPost, "/api/v1/driver/documents", `{"document_type":"license"}`, driverToken)
	if status != http.StatusCreated || document["status"] != "pending" {
		t.Fatalf("document response = %d %#v", status, document)
	}
	status, _ = requestJSON(t, client, http.MethodGet, "/api/v1/users/me", `{}`, passengerToken)
	if status != http.StatusOK {
		t.Fatalf("me status = %d", status)
	}
}

type handlerClient struct{ handler http.Handler }

func (c *handlerClient) Do(request *http.Request) (*http.Response, error) {
	recorder := httptest.NewRecorder()
	c.handler.ServeHTTP(recorder, request)
	return recorder.Result(), nil
}

func requestJSON(t *testing.T, client interface {
	Do(*http.Request) (*http.Response, error)
}, method, url, body, bearer string) (int, map[string]any) {
	t.Helper()
	request, err := http.NewRequest(method, url, bytes.NewBufferString(body))
	if err != nil {
		t.Fatal(err)
	}
	request.Header.Set("Content-Type", "application/json")
	if bearer != "" {
		request.Header.Set("Authorization", "Bearer "+bearer)
	}
	response, err := client.Do(request)
	if err != nil {
		t.Fatal(err)
	}
	defer response.Body.Close()
	var value map[string]any
	if err := json.NewDecoder(response.Body).Decode(&value); err != nil {
		t.Fatal(err)
	}
	return response.StatusCode, value
}

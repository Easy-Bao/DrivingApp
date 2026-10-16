package request

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestDecodeJSONRejectsUnknownFieldsAndTrailingDocuments(t *testing.T) {
	tests := []struct {
		name string
		body string
	}{
		{name: "unknown field", body: `{"name":"Passenger","admin":true}`},
		{name: "trailing document", body: `{"name":"Passenger"}{"name":"Driver"}`},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			request := httptest.NewRequest(http.MethodPost, "/", strings.NewReader(test.body))
			response := httptest.NewRecorder()
			var input struct {
				Name string `json:"name"`
			}

			if err := DecodeJSON(response, request, &input, 1<<10); err == nil {
				t.Fatal("expected malformed contract to be rejected")
			}
		})
	}
}

func TestDecodeJSONEnforcesBodyLimit(t *testing.T) {
	request := httptest.NewRequest(http.MethodPost, "/", bytes.NewBufferString(`{"name":"Passenger"}`))
	response := httptest.NewRecorder()
	var input struct {
		Name string `json:"name"`
	}

	if err := DecodeJSON(response, request, &input, 8); err == nil {
		t.Fatal("expected oversized body to be rejected")
	}
}

func TestDecodeJSONV2RejectsAmbiguousOrUnknownDocuments(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name string
		body string
	}{
		{name: "unknown field", body: `{"name":"Passenger","admin":true}`},
		{name: "duplicate field", body: `{"name":"Passenger","name":"Driver"}`},
		{name: "trailing document", body: `{"name":"Passenger"}{"name":"Driver"}`},
	}

	for _, test := range tests {
		test := test
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			request := httptest.NewRequest(http.MethodPost, "/", strings.NewReader(test.body))
			response := httptest.NewRecorder()
			var input struct {
				Name string `json:"name"`
			}

			if err := DecodeJSONV2(response, request, &input, 1<<10); err == nil {
				t.Fatal("expected malformed contract to be rejected")
			}
		})
	}
}

func TestDecodeJSONV2RetainsCaseInsensitiveFieldMatching(t *testing.T) {
	t.Parallel()

	request := httptest.NewRequest(http.MethodPost, "/", strings.NewReader(`{"Name":"Passenger"}`))
	response := httptest.NewRecorder()
	var input struct {
		Name string `json:"name"`
	}

	if err := DecodeJSONV2(response, request, &input, 1<<10); err != nil {
		t.Fatalf("DecodeJSONV2() error = %v", err)
	}
	if input.Name != "Passenger" {
		t.Fatalf("name = %q, want Passenger", input.Name)
	}
}

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

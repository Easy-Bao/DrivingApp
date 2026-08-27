package http

import (
	"encoding/json"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
)

func TestAuthSessionResponseVerificationState(t *testing.T) {
	account := domain.User{ID: 7, Email: "passenger@example.com", Role: domain.Passenger}

	tests := []struct {
		name     string
		verified bool
		wantKey  bool
	}{
		{name: "verified session", verified: true, wantKey: true},
		{name: "unverified session", verified: false, wantKey: false},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			payload := authSessionResponse(account, "access", "refresh", !test.verified, test.verified)
			encoded, err := json.Marshal(payload)
			if err != nil {
				t.Fatalf("marshal session response: %v", err)
			}

			var body struct {
				Data struct {
					Verified bool `json:"verified"`
				} `json:"data"`
			}
			if err := json.Unmarshal(encoded, &body); err != nil {
				t.Fatalf("unmarshal session response: %v", err)
			}
			if body.Data.Verified != test.verified {
				t.Fatalf("verified = %t, want %t", body.Data.Verified, test.verified)
			}

			var raw map[string]any
			if err := json.Unmarshal(encoded, &raw); err != nil {
				t.Fatalf("unmarshal raw session response: %v", err)
			}
			data, ok := raw["data"].(map[string]any)
			if !ok {
				t.Fatal("session response data is not an object")
			}
			_, hasVerifiedKey := data["verified"]
			if hasVerifiedKey != test.wantKey {
				t.Fatalf("verified key present = %t, want %t", hasVerifiedKey, test.wantKey)
			}
		})
	}
}

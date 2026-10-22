package http

import (
	"encoding/json"
	"net/http"
	"testing"

	authapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/domain"
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
			payload := authSessionResponse(
				account,
				authapp.SessionTokens{AccessToken: "access", RefreshToken: "refresh"},
				!test.verified,
				test.verified,
			)
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

func TestAuthSessionResponseKeepsAccountFieldsAtTheHTTPBoundary(t *testing.T) {
	payload := authSessionResponse(
		domain.User{
			ID:           7,
			Email:        "driver@example.com",
			Phone:        "+639171234567",
			Name:         "Ada Driver",
			Role:         domain.Driver,
			PasswordHash: "must-not-leak",
			IsVerified:   true,
			VehicleType:  "Motorcycle",
			PlateNumber:  "ABC123",
		},
		authapp.SessionTokens{AccessToken: "access", RefreshToken: "refresh"},
		false,
		true,
	)
	encoded, err := json.Marshal(payload)
	if err != nil {
		t.Fatalf("marshal session response: %v", err)
	}

	var body map[string]any
	if err := json.Unmarshal(encoded, &body); err != nil {
		t.Fatalf("unmarshal session response: %v", err)
	}
	data, ok := body["data"].(map[string]any)
	if !ok {
		t.Fatal("session response data is not an object")
	}
	user, ok := data["user"].(map[string]any)
	if !ok {
		t.Fatal("session response user is not an object")
	}
	if user["isVerified"] != true || user["vehicleType"] != "Motorcycle" ||
		user["plateNumber"] != "ABC123" {
		t.Fatalf("unexpected account response fields: %#v", user)
	}
	for _, field := range []string{"PasswordHash", "password_hash", "passwordHash"} {
		if _, exists := user[field]; exists {
			t.Fatalf("account response leaked %q: %#v", field, user)
		}
	}
}

func TestOTPMaxAttemptsReturnTooManyRequests(t *testing.T) {
	if status := otpErrorStatus(domain.ErrOTPMaxAttemptsExceeded); status != http.StatusTooManyRequests {
		t.Fatalf("status = %d, want %d", status, http.StatusTooManyRequests)
	}
	if message := safeAuthError(domain.ErrOTPMaxAttemptsExceeded); message == "" {
		t.Fatal("expected an informative OTP lockout message")
	}
}

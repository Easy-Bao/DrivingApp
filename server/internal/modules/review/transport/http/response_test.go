package http

import (
	"encoding/json"
	"errors"
	"testing"

	application "github.com/Easy-Bao/DrivingApp/server/internal/modules/review/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/review/domain"
)

func TestReviewResponseMappersPreserveWireShapes(t *testing.T) {
	tests := []struct {
		name  string
		value any
		want  string
	}{
		{
			name: "driver review",
			value: NewReviewResponse(domain.Review{
				ID: 2, RideID: 17, DriverID: 9, PassengerID: 4,
				PassengerName: "Ada Passenger", Rating: 5,
				Comment: "Great trip", CreatedAt: "2026-10-12T14:00:00Z",
			}),
			want: `{"id":2,"ride_id":17,"driver_id":9,"passenger_id":4,"passenger_name":"Ada Passenger","rating":5,"comment":"Great trip","created_at":"2026-10-12T14:00:00Z"}`,
		},
		{
			name:  "driver review omits optional fields",
			value: NewReviewResponses([]domain.Review{{ID: 2, RideID: 17, Rating: 5}}),
			want:  `[{"id":2,"ride_id":17,"driver_id":0,"passenger_id":0,"rating":5,"created_at":""}]`,
		},
		{
			name: "passenger review",
			value: NewPassengerReviewResponse(domain.PassengerReview{
				ID: 3, RideID: 17, DriverID: 9, PassengerID: 4,
				Rating: 4, Comment: "Friendly passenger", CreatedAt: "2026-10-12T14:00:00Z",
			}),
			want: `{"id":3,"ride_id":17,"driver_id":9,"passenger_id":4,"rating":4,"comment":"Friendly passenger","created_at":"2026-10-12T14:00:00Z"}`,
		},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			encoded, err := json.Marshal(test.value)
			if err != nil {
				t.Fatalf("json.Marshal() error = %v", err)
			}
			if string(encoded) != test.want {
				t.Fatalf("response = %s, want %s", encoded, test.want)
			}
		})
	}
}

func TestNewReviewResponsesPreservesNil(t *testing.T) {
	if NewReviewResponses(nil) != nil {
		t.Fatal("NewReviewResponses(nil) returned a non-nil slice")
	}
}

func TestSafeReviewError(t *testing.T) {
	tests := []struct {
		err      error
		wantMsg  string
		wantCode int
	}{
		{
			err:      domain.ErrReviewNotAllowed,
			wantMsg:  "Reviews are available after a completed ride.",
			wantCode: 400,
		},
		{
			err:      domain.ErrInvalidRating,
			wantMsg:  "Rating must be between 1 and 5.",
			wantCode: 400,
		},
		{
			err:      application.ErrPersistenceUnavailable,
			wantMsg:  "Review service is temporarily unavailable.",
			wantCode: 503,
		},
		{
			err:      errors.New("unexpected database error"),
			wantMsg:  "The review could not be submitted. Please try again.",
			wantCode: 500,
		},
	}
	for _, tc := range tests {
		if got := safeReviewError(tc.err); got != tc.wantMsg {
			t.Errorf("safeReviewError(%v) = %q, want %q", tc.err, got, tc.wantMsg)
		}
		if got := reviewErrorStatus(tc.err); got != tc.wantCode {
			t.Errorf("reviewErrorStatus(%v) = %d, want %d", tc.err, got, tc.wantCode)
		}
	}
}

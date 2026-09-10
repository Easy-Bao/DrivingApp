package ports

import (
	"context"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

// PassengerActivityReader isolates passenger dashboard reads from ride commands.
type PassengerActivityReader interface {
	PassengerActivitySummary(ctx context.Context, passengerID int, weekStart, weekEnd time.Time) (domain.PassengerActivitySummary, error)
}

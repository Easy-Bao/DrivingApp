package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

// SafetyReportStore persists incidents separately from service-quality ratings.
type SafetyReportStore interface {
	CreateSafetyReport(ctx context.Context, report domain.SafetyReport) (domain.SafetyReport, error)
}

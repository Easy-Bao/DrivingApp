package postgres

import (
	"testing"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/jackc/pgx/v5/pgtype"
)

func TestFromPostgresSafetyReportMapsEvidenceLink(t *testing.T) {
	createdAt := time.Date(2026, time.January, 2, 3, 4, 5, 0, time.FixedZone("PHT", 8*60*60))
	report, err := fromPostgresSafetyReport(databasepostgres.RideReport{
		ID:             9,
		RideID:         23,
		ReporterID:     7,
		ReportedUserID: 11,
		ReporterRole:   "passenger",
		Category:       "unsafe_driving",
		Severity:       "high",
		Description:    "The driver was using the wrong lane.",
		Status:         "submitted",
		CreatedAt:      pgtype.Timestamptz{Time: createdAt, Valid: true},
	})
	if err != nil {
		t.Fatalf("fromPostgresSafetyReport() error = %v", err)
	}
	if report.ID != 9 || report.RideID != 23 || report.ReporterID != 7 ||
		report.ReportedUserID != 11 || report.Category != domain.SafetyReportUnsafeDriving ||
		report.Severity != domain.SafetyReportHigh || report.Status != domain.SafetyReportSubmitted {
		t.Fatalf("mapped safety report = %+v", report)
	}
	if report.CreatedAt != "2026-01-01T19:04:05Z" {
		t.Fatalf("mapped report creation time = %q", report.CreatedAt)
	}
}

package postgres

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
	"github.com/jackc/pgx/v5"
)

var _ ports.SafetyReportStore = (*RideRepository)(nil)

func (repository *RideRepository) CreateSafetyReport(
	ctx context.Context,
	report domain.SafetyReport,
) (domain.SafetyReport, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return domain.SafetyReport{}, err
	}
	reporterRole := strings.ToLower(strings.TrimSpace(report.ReporterRole))
	category := domain.SafetyReportCategory(
		strings.ToLower(strings.TrimSpace(string(report.Category))),
	)
	description := strings.TrimSpace(report.Description)
	severity, valid := domain.ValidateSafetyReport(reporterRole, category, description)
	if !valid {
		return domain.SafetyReport{}, domain.ErrSafetyReportInvalid
	}

	reportID, err := toPostgresRideID(report.RideID, "ride id")
	if err != nil {
		return domain.SafetyReport{}, domain.ErrSafetyReportNotAllowed
	}
	reporterID, err := toPostgresRideID(report.ReporterID, "reporter id")
	if err != nil {
		return domain.SafetyReport{}, domain.ErrSafetyReportNotAllowed
	}
	item, err := repository.queries.CreateRideReport(ctx, databasepostgres.CreateRideReportParams{
		RideID:       reportID,
		ReporterID:   reporterID,
		ReporterRole: reporterRole,
		Category:     string(category),
		Severity:     string(severity),
		Description:  description,
	})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return domain.SafetyReport{}, domain.ErrSafetyReportNotAllowed
		}
		if isPostgresUniqueViolation(err) {
			existing, lookupErr := repository.queries.GetRideReportByReporterCategory(
				ctx,
				databasepostgres.GetRideReportByReporterCategoryParams{
					RideID:     reportID,
					ReporterID: reporterID,
					Category:   string(category),
				},
			)
			if lookupErr != nil {
				return domain.SafetyReport{}, fmt.Errorf("recover existing ride safety report: %w", lookupErr)
			}
			recovered, mappingErr := fromPostgresSafetyReport(existing)
			if mappingErr != nil {
				return domain.SafetyReport{}, fmt.Errorf("map recovered ride safety report: %w", mappingErr)
			}
			return recovered, nil
		}
		return domain.SafetyReport{}, fmt.Errorf("create ride safety report: %w", err)
	}
	created, err := fromPostgresSafetyReport(item)
	if err != nil {
		return domain.SafetyReport{}, fmt.Errorf("map created ride safety report: %w", err)
	}
	return created, nil
}

func fromPostgresSafetyReport(item databasepostgres.RideReport) (domain.SafetyReport, error) {
	if !item.CreatedAt.Valid {
		return domain.SafetyReport{}, errors.New("safety report creation time is null")
	}
	return domain.SafetyReport{
		ID:             int(item.ID),
		RideID:         int(item.RideID),
		ReporterID:     int(item.ReporterID),
		ReportedUserID: int(item.ReportedUserID),
		ReporterRole:   item.ReporterRole,
		Category:       domain.SafetyReportCategory(item.Category),
		Severity:       domain.SafetyReportSeverity(item.Severity),
		Description:    item.Description,
		Status:         domain.SafetyReportStatus(item.Status),
		CreatedAt:      item.CreatedAt.Time.UTC().Format(time.RFC3339),
	}, nil
}

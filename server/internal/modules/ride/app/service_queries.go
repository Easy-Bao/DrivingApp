package app

import (
	"context"
	"errors"
	"fmt"
	"slices"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
)

func (service *Service) DriverStats(ctx context.Context, driverID int) (domain.DriverStats, error) {
	if service == nil || service.driverStats == nil {
		return domain.DriverStats{}, errors.New("driver analytics persistence is unavailable")
	}
	dayStart, dayEnd := service.reportingDayBounds(time.Now())
	stats, err := service.driverStats.DriverStats(
		ctx,
		driverID,
		dayStart,
		dayEnd,
	)
	if err != nil {
		return domain.DriverStats{}, fmt.Errorf("load driver statistics: %w", err)
	}
	return stats, nil
}

func (service *Service) DriverEarnings(ctx context.Context, driverID int) (domain.DriverEarningsSummary, error) {
	if service == nil || service.driverEarnings == nil {
		return domain.DriverEarningsSummary{}, errors.New("driver earnings persistence is unavailable")
	}
	location := service.reportingLocationOrDefault()
	now := time.Now().In(location)
	queryStart, queryEnd := driverEarningsQueryBounds(now, location)
	entries, err := service.driverEarnings.DriverEarnings(
		ctx,
		driverID,
		queryStart,
		queryEnd,
	)
	if err != nil {
		return domain.DriverEarningsSummary{}, fmt.Errorf("load driver earnings: %w", err)
	}
	return summarizeDriverEarnings(entries, now, location), nil
}

func (service *Service) DriverTrips(
	ctx context.Context,
	driverID int,
	query domain.TripHistoryQuery,
) ([]domain.Ride, error) {
	if service == nil || service.history == nil {
		return nil, errors.New("driver trip persistence is unavailable")
	}
	if err := validateTripHistoryQuery(query); err != nil {
		return nil, err
	}
	rides, err := service.history.DriverTrips(ctx, driverID, query)
	if err != nil {
		return nil, fmt.Errorf("load driver trips: %w", err)
	}
	return slices.Clone(rides), nil
}

func (service *Service) PassengerRides(
	ctx context.Context,
	passengerID int,
	query domain.TripHistoryQuery,
) ([]domain.Ride, error) {
	if service == nil || service.history == nil {
		return nil, errors.New("passenger ride persistence is unavailable")
	}
	if err := validateTripHistoryQuery(query); err != nil {
		return nil, err
	}
	rides, err := service.history.PassengerRides(ctx, passengerID, query)
	if err != nil {
		return nil, fmt.Errorf("load passenger rides: %w", err)
	}
	return slices.Clone(rides), nil
}

func (service *Service) PassengerActivitySummary(
	ctx context.Context,
	passengerID int,
) (domain.PassengerActivitySummary, error) {
	if service == nil || service.passengerActivity == nil {
		return domain.PassengerActivitySummary{}, errors.New("passenger activity persistence is unavailable")
	}
	weekStart, weekEnd := service.reportingWeekBounds(time.Now())
	activity, err := service.passengerActivity.PassengerActivitySummary(
		ctx,
		passengerID,
		weekStart,
		weekEnd,
	)
	if err != nil {
		return domain.PassengerActivitySummary{}, fmt.Errorf("load passenger activity summary: %w", err)
	}
	return activity, nil
}

func (service *Service) PassengerRecentRides(ctx context.Context, passengerID, limit int) ([]domain.Ride, error) {
	invalidPassengerID := passengerID <= 0
	invalidLimit := limit <= 0 || limit > 100
	if invalidPassengerID || invalidLimit {
		return nil, errors.New("invalid passenger recent rides request")
	}
	if service != nil && service.recentRides != nil {
		rides, err := service.recentRides.PassengerRecentRides(ctx, passengerID, limit)
		if err != nil {
			return nil, fmt.Errorf("load recent passenger rides: %w", err)
		}
		return slices.Clone(rides), nil
	}
	rides, err := service.PassengerRides(ctx, passengerID, domain.TripHistoryQuery{Limit: limit, Offset: 0})
	if err != nil {
		return nil, fmt.Errorf("load recent passenger rides through trip history: %w", err)
	}
	if len(rides) > limit {
		return slices.Clone(rides[:limit]), nil
	}
	return slices.Clone(rides), nil
}

func (service *Service) CreateSafetyReport(
	ctx context.Context,
	report domain.SafetyReport,
) (domain.SafetyReport, error) {
	if service == nil || service.safetyReports == nil {
		return domain.SafetyReport{}, errors.New("safety report persistence is unavailable")
	}
	report.ReporterRole = strings.ToLower(strings.TrimSpace(report.ReporterRole))
	report.Category = domain.SafetyReportCategory(
		strings.ToLower(strings.TrimSpace(string(report.Category))),
	)
	report.Description = strings.TrimSpace(report.Description)
	severity, valid := domain.ValidateSafetyReport(
		report.ReporterRole,
		report.Category,
		report.Description,
	)
	if !valid {
		return domain.SafetyReport{}, domain.ErrSafetyReportInvalid
	}
	report.Severity = severity
	created, err := service.safetyReports.CreateSafetyReport(ctx, report)
	if err != nil {
		return domain.SafetyReport{}, fmt.Errorf("create safety report: %w", err)
	}
	return created, nil
}

func validateTripHistoryQuery(query domain.TripHistoryQuery) error {
	invalidLimit := query.Limit <= 0 || query.Limit > 100
	invalidOffset := query.Offset < 0 || query.Offset > 1_000_000
	if invalidLimit || invalidOffset {
		return errors.New("trip history pagination is invalid")
	}
	if query.ActiveOnly && query.Limit > 20 {
		return errors.New("active trip history limit is invalid")
	}
	return nil
}

package assignment

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	ridedomain "github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/jackc/pgx/v5"
)

type RideRepository = RideAuthority

type RideRepositoryLookup struct {
	repository RideAuthority
}

var _ Lookup = (*RideRepositoryLookup)(nil)

func NewRideRepositoryLookup(repository RideRepository) *RideRepositoryLookup {
	return &RideRepositoryLookup{repository: repository}
}

// RideLookup is the canonical name for the assignment adapter. The original
// type and constructor remain available for existing internal callers.
type RideLookup = RideRepositoryLookup

func NewRideLookup(source RideAuthority) *RideLookup {
	return NewRideRepositoryLookup(source)
}

func (lookup *RideRepositoryLookup) ForRide(
	ctx context.Context,
	rideID string,
) (Assignment, bool, error) {
	if lookup == nil || lookup.repository == nil {
		return Assignment{}, false, fmt.Errorf("ride authority is unavailable")
	}
	id, err := parseID(rideID)
	if err != nil {
		return Assignment{}, false, nil
	}
	ride, err := lookup.repository.Get(ctx, id)
	if err != nil {
		if isRideNotFound(err) {
			return Assignment{}, false, nil
		}
		return Assignment{}, false, fmt.Errorf("load ride assignment: %w", err)
	}
	value, ok := fromRide(ride)
	return value, ok, nil
}

func isRideNotFound(err error) bool {
	return errors.Is(err, pgx.ErrNoRows)
}

func (lookup *RideRepositoryLookup) ForDriver(
	ctx context.Context,
	driverID string,
) ([]Assignment, error) {
	if lookup == nil || lookup.repository == nil {
		return nil, fmt.Errorf("ride authority is unavailable")
	}
	id, err := parseID(driverID)
	if err != nil {
		return []Assignment{}, nil
	}
	rides, err := lookup.repository.ActiveRidesForDriver(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("load driver ride assignments: %w", err)
	}
	result := make([]Assignment, 0, len(rides))
	for _, ride := range rides {
		if value, ok := fromRide(ride); ok {
			result = append(result, value)
		}
	}
	return result, nil
}

func fromRide(ride ridedomain.Ride) (Assignment, bool) {
	invalidRideID := ride.ID <= 0
	invalidPassengerID := ride.PassengerID <= 0
	invalidDriverID := ride.DriverID == nil || *ride.DriverID <= 0
	if invalidRideID || invalidPassengerID || invalidDriverID {
		return Assignment{}, false
	}
	value := Assignment{
		RideID:      strconv.Itoa(ride.ID),
		PassengerID: strconv.Itoa(ride.PassengerID),
		DriverID:    strconv.Itoa(*ride.DriverID),
		Status:      ride.Status,
	}
	value.ContactOpen = value.Active() || completedWithinContactWindow(ride.CompletedAt)
	return value, true
}

func completedWithinContactWindow(completedAt *string) bool {
	if completedAt == nil {
		return false
	}
	completed, err := time.Parse(time.RFC3339, strings.TrimSpace(*completedAt))
	if err != nil {
		return false
	}
	age := time.Since(completed)
	return age >= 0 && age <= 48*time.Hour
}

func parseID(value string) (int, error) {
	id, err := strconv.Atoi(strings.TrimSpace(value))
	if err != nil || id <= 0 {
		return 0, fmt.Errorf("invalid id")
	}
	return id, nil
}

package app

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	ridedomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
)

type RideLookup struct {
	repository RideAuthority
}

var _ Lookup = (*RideLookup)(nil)

func NewRideLookup(source RideAuthority) *RideLookup {
	return &RideLookup{repository: source}
}

func (lookup *RideLookup) ForRide(
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
		if errors.Is(err, ridedomain.ErrRideNotFound) {
			return Assignment{}, false, nil
		}
		return Assignment{}, false, fmt.Errorf("load ride assignment: %w", err)
	}
	value, ok := fromRide(ride)
	return value, ok, nil
}

func (lookup *RideLookup) ForDriver(
	ctx context.Context,
	driverID string,
) ([]Assignment, error) {
	if lookup == nil || lookup.repository == nil {
		return nil, fmt.Errorf("ride authority is unavailable")
	}
	id, err := parseID(driverID)
	if err != nil {
		return nil, nil
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
	if ride.CompletedAt != nil {
		if completed, err := parseTimestamp(*ride.CompletedAt); err == nil {
			value.CompletedAt = &completed
		}
	}
	value.ContactOpen = value.AllowsCommunication()
	return value, true
}

func parseTimestamp(value string) (time.Time, error) {
	trimmed := strings.TrimSpace(value)
	if t, err := time.Parse(time.RFC3339Nano, trimmed); err == nil {
		return t, nil
	}
	return time.Parse(time.RFC3339, trimmed)
}

func parseID(value string) (int, error) {
	id, err := strconv.Atoi(strings.TrimSpace(value))
	if err != nil || id <= 0 {
		return 0, fmt.Errorf("invalid id")
	}
	return id, nil
}

package adapter

import (
	"context"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/assignment"
	ridesdomain "github.com/Easy-Bao/DrivingApp/server/internal/rides/domain"
)

type RideRepository interface {
	Get(ctx context.Context, id int) (ridesdomain.Ride, error)
	ActiveRidesForDriver(ctx context.Context, driverID int) ([]ridesdomain.Ride, error)
}

type RideRepositoryLookup struct {
	repository RideRepository
}

func NewRideRepositoryLookup(repository RideRepository) *RideRepositoryLookup {
	return &RideRepositoryLookup{repository: repository}
}

func (lookup *RideRepositoryLookup) ForRide(ctx context.Context, rideID string) (assignment.Assignment, bool, error) {
	if lookup == nil || lookup.repository == nil {
		return assignment.Assignment{}, false, fmt.Errorf("ride repository is unavailable")
	}
	id, err := parseID(rideID)
	if err != nil {
		return assignment.Assignment{}, false, nil
	}
	ride, err := lookup.repository.Get(ctx, id)
	if err != nil {
		if ent.IsNotFound(err) {
			return assignment.Assignment{}, false, nil
		}
		return assignment.Assignment{}, false, fmt.Errorf("load ride assignment: %w", err)
	}
	value, ok := fromRide(ride)
	return value, ok, nil
}

func (lookup *RideRepositoryLookup) ForDriver(ctx context.Context, driverID string) ([]assignment.Assignment, error) {
	if lookup == nil || lookup.repository == nil {
		return nil, fmt.Errorf("ride repository is unavailable")
	}
	id, err := parseID(driverID)
	if err != nil {
		return nil, nil
	}
	rides, err := lookup.repository.ActiveRidesForDriver(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("load driver ride assignments: %w", err)
	}
	result := make([]assignment.Assignment, 0, len(rides))
	for _, ride := range rides {
		if value, ok := fromRide(ride); ok {
			result = append(result, value)
		}
	}
	return result, nil
}

func fromRide(ride ridesdomain.Ride) (assignment.Assignment, bool) {
	if ride.ID <= 0 || ride.PassengerID <= 0 || ride.DriverID == nil || *ride.DriverID <= 0 {
		return assignment.Assignment{}, false
	}
	value := assignment.Assignment{
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

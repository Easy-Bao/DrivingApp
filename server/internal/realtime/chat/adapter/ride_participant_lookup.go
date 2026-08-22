package adapter

import (
	"context"
	"fmt"
	"strconv"
	"strings"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	geodomain "github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/domain"
	ridesdomain "github.com/Easy-Bao/DrivingApp/server/internal/rides/domain"
)

type RideReader interface {
	Get(ctx context.Context, id int) (ridesdomain.Ride, error)
}

type RideParticipantLookup struct {
	repository RideReader
}

func NewRideParticipantLookup(repository RideReader) *RideParticipantLookup {
	return &RideParticipantLookup{repository: repository}
}

func (lookup *RideParticipantLookup) ForRide(
	ctx context.Context,
	rideID string,
) (geodomain.RideAssignment, bool, error) {
	if lookup == nil || lookup.repository == nil {
		return geodomain.RideAssignment{}, false, fmt.Errorf("ride repository is unavailable")
	}

	id, err := strconv.Atoi(strings.TrimSpace(rideID))
	if err != nil || id <= 0 {
		return geodomain.RideAssignment{}, false, nil
	}

	ride, err := lookup.repository.Get(ctx, id)
	if err != nil {
		if ent.IsNotFound(err) {
			return geodomain.RideAssignment{}, false, nil
		}
		return geodomain.RideAssignment{}, false, fmt.Errorf("load ride participants: %w", err)
	}
	if ride.PassengerID <= 0 || ride.DriverID == nil || *ride.DriverID <= 0 {
		return geodomain.RideAssignment{}, false, nil
	}

	return geodomain.RideAssignment{
		RideID:      strconv.Itoa(ride.ID),
		PassengerID: strconv.Itoa(ride.PassengerID),
		DriverID:    strconv.Itoa(*ride.DriverID),
	}, true, nil
}

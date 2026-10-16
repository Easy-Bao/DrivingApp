package app

import (
	"context"
	"strconv"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
)

const (
	_rideCreatedEvent       = event.RideOfferCreated
	_rideStatusChangedEvent = event.RideStatusChanged
)

func (service *RideService) publishRide(
	ctx context.Context,
	eventType event.Type,
	ride domain.Ride,
	payload map[string]any,
) {
	scope := event.Scope{
		RideID:      positiveIdentifier(ride.ID),
		PassengerID: positiveIdentifier(ride.PassengerID),
	}
	if ride.DriverID != nil {
		scope.DriverID = positiveIdentifier(*ride.DriverID)
	}
	service.publish(
		ctx,
		eventType,
		scope,
		payload,
	)
}

func (service *RideService) publish(
	ctx context.Context,
	eventType event.Type,
	scope event.Scope,
	payload map[string]any,
) {
	if service.eventPublisher == nil {
		return
	}
	if err := service.eventPublisher.Publish(ctx, RealtimeEvent{
		Type:    eventType,
		Scope:   scope,
		Payload: payload,
	}); err != nil {
		service.log().WarnContext(ctx, "publish realtime ride event failed", "error", err, "event_type", eventType)
	}
}

func positiveIdentifier(value int) string {
	if value <= 0 {
		return ""
	}
	return strconv.Itoa(value)
}

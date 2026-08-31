package application

import (
	"context"
	"strconv"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/event"
	"github.com/Easy-Bao/DrivingApp/server/internal/rides/domain"
)

const (
	rideCreatedEvent       = event.RideOfferCreated
	rideOfferUpdatedEvent  = event.RideOfferUpdated
	rideMatchedEvent       = event.RideMatched
	rideStatusChangedEvent = event.RideStatusChanged
)

func (service *RideService) publishRide(ctx context.Context, eventType event.Type, ride domain.Ride, payload map[string]any) {
	scope := event.Scope{
		RideID:      positiveIdentifier(ride.ID),
		PassengerID: positiveIdentifier(ride.PassengerID),
	}
	if ride.DriverID != nil {
		scope.DriverID = positiveIdentifier(*ride.DriverID)
	}
	service.publish(ctx, eventType, scope, payload)
}

func (service *RideService) publishSession(ctx context.Context, eventType event.Type, session domain.BidSession, payload map[string]any) {
	// A bid session is not yet an authoritative ride. Its identifier belongs in
	// the payload, while the event itself is scoped to the verified participants.
	scope := event.Scope{
		PassengerID: positiveIdentifier(session.PassengerID),
		DriverPool:  session.TargetDriverID == nil && session.AcceptedDriverID == nil,
	}
	if session.TargetDriverID != nil {
		scope.DriverID = positiveIdentifier(*session.TargetDriverID)
	}
	if session.AcceptedDriverID != nil {
		scope.DriverID = positiveIdentifier(*session.AcceptedDriverID)
	}
	service.publish(ctx, eventType, scope, payload)
}

func (service *RideService) publishDriverOffer(ctx context.Context, offer domain.BidOffer, payload map[string]any) {
	service.publish(ctx, rideOfferUpdatedEvent, event.Scope{DriverID: positiveIdentifier(offer.DriverID)}, payload)
}

func (service *RideService) publish(ctx context.Context, eventType event.Type, scope event.Scope, payload map[string]any) {
	if service.eventPublisher == nil {
		return
	}
	envelope, err := event.New(event.NewID(), eventType, time.Now(), scope, payload)
	if err != nil {
		service.logger.ErrorContext(ctx, "construct realtime ride event failed", "error", err, "event_type", eventType)
		return
	}
	if err := service.eventPublisher.Publish(ctx, envelope); err != nil {
		service.logger.WarnContext(ctx, "publish realtime ride event failed", "error", err, "event_type", eventType)
	}
}

func positiveIdentifier(value int) string {
	if value <= 0 {
		return ""
	}
	return strconv.Itoa(value)
}

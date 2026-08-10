package usecase

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"log"
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

func firstPublisher(publishers []domain.EventPublisher) domain.EventPublisher {
	if len(publishers) == 0 {
		return nil
	}
	return publishers[0]
}

func (service *Service) publishRide(ctx context.Context, eventType event.Type, ride domain.Ride, payload map[string]any) {
	scope := event.Scope{
		RideID:      positiveIdentifier(ride.ID),
		PassengerID: positiveIdentifier(ride.PassengerID),
	}
	if ride.DriverID != nil {
		scope.DriverID = positiveIdentifier(*ride.DriverID)
	}
	service.publish(ctx, eventType, scope, payload)
}

func (service *Service) publishSession(ctx context.Context, eventType event.Type, session domain.BidSession, payload map[string]any) {
	// A bid session is not yet an authoritative ride. Its identifier belongs in
	// the payload, while the event itself is scoped to the verified participants.
	scope := event.Scope{PassengerID: positiveIdentifier(session.PassengerID)}
	if session.TargetDriverID != nil {
		scope.DriverID = positiveIdentifier(*session.TargetDriverID)
	}
	if session.AcceptedDriverID != nil {
		scope.DriverID = positiveIdentifier(*session.AcceptedDriverID)
	}
	service.publish(ctx, eventType, scope, payload)
}

func (service *Service) publishDriverOffer(ctx context.Context, offer domain.BidOffer, payload map[string]any) {
	service.publish(ctx, rideOfferUpdatedEvent, event.Scope{DriverID: positiveIdentifier(offer.DriverID)}, payload)
}

func (service *Service) publish(ctx context.Context, eventType event.Type, scope event.Scope, payload map[string]any) {
	if service.eventPublisher == nil {
		return
	}
	envelope, err := event.New(nextEventID(), eventType, time.Now(), scope, payload)
	if err != nil {
		log.Printf("realtime event construction failed: %v", err)
		return
	}
	if err := service.eventPublisher.Publish(ctx, envelope); err != nil {
		log.Printf("realtime event publishing failed: %v", err)
	}
}

func positiveIdentifier(value int) string {
	if value <= 0 {
		return ""
	}
	return strconv.Itoa(value)
}

func nextEventID() string {
	var bytes [16]byte
	if _, err := rand.Read(bytes[:]); err == nil {
		return hex.EncodeToString(bytes[:])
	}
	return strconv.FormatInt(time.Now().UnixNano(), 10)
}

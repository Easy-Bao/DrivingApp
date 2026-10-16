package http

import (
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/domain"
	ridedto "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/transport/http"
)

type BidSessionResponse struct {
	ID                int                `json:"id"`
	PassengerID       int                `json:"passenger_id"`
	RideType          string             `json:"ride_type"`
	PickupLatitude    float64            `json:"pickup_latitude"`
	PickupLongitude   float64            `json:"pickup_longitude"`
	PickupName        string             `json:"pickup_name"`
	DropoffLatitude   float64            `json:"dropoff_latitude"`
	DropoffLongitude  float64            `json:"dropoff_longitude"`
	DropoffName       string             `json:"dropoff_name"`
	PassengerNote     string             `json:"passenger_note,omitempty"`
	DistanceKm        float64            `json:"distance_km"`
	DurationMinutes   float64            `json:"duration_minutes"`
	OfferedFareAmount int64              `json:"offered_fare"`
	CustomFareAmount  *int64             `json:"custom_fare,omitempty"`
	Status            string             `json:"status"`
	TargetDriverID    *int               `json:"target_driver_id,omitempty"`
	AcceptedDriverID  *int               `json:"accepted_driver_id,omitempty"`
	ExpiresAt         time.Time          `json:"expires_at"`
	CreatedAt         time.Time          `json:"created_at"`
	Offers            []BidOfferResponse `json:"offers,omitempty"`
}

type BidOfferResponse struct {
	ID                 int64     `json:"id"`
	SessionID          int       `json:"session_id"`
	DriverID           int       `json:"driver_id"`
	DriverName         string    `json:"driver_name,omitempty"`
	PlateNumber        string    `json:"plate_number,omitempty"`
	VehicleType        string    `json:"vehicle_type,omitempty"`
	ProposedFareAmount int64     `json:"proposed_fare"`
	Status             string    `json:"status"`
	CreatedAt          time.Time `json:"created_at"`
}

type AcceptedOfferResponse struct {
	Session BidSessionResponse   `json:"session"`
	Offer   BidOfferResponse     `json:"offer"`
	Ride    ridedto.RideResponse `json:"ride"`
	RideID  int                  `json:"ride_id"`
}

func NewBidSessionResponse(session domain.BidSession) BidSessionResponse {
	return BidSessionResponse{
		ID:                session.ID,
		PassengerID:       session.PassengerID,
		RideType:          session.RideType,
		PickupLatitude:    session.PickupLatitude,
		PickupLongitude:   session.PickupLongitude,
		PickupName:        session.PickupName,
		DropoffLatitude:   session.DropoffLatitude,
		DropoffLongitude:  session.DropoffLongitude,
		DropoffName:       session.DropoffName,
		PassengerNote:     session.PassengerNote,
		DistanceKm:        session.DistanceKm,
		DurationMinutes:   session.DurationMinutes,
		OfferedFareAmount: session.OfferedFareAmount,
		CustomFareAmount:  session.CustomFareAmount,
		Status:            session.Status,
		TargetDriverID:    session.TargetDriverID,
		AcceptedDriverID:  session.AcceptedDriverID,
		ExpiresAt:         session.ExpiresAt,
		CreatedAt:         session.CreatedAt,
		Offers:            NewBidOfferResponses(session.Offers),
	}
}

func NewBidSessionResponses(sessions []domain.BidSession) []BidSessionResponse {
	if sessions == nil {
		return nil
	}

	responses := make([]BidSessionResponse, 0, len(sessions))
	for _, session := range sessions {
		responses = append(responses, NewBidSessionResponse(session))
	}
	return responses
}

func NewBidOfferResponse(offer domain.BidOffer) BidOfferResponse {
	return BidOfferResponse{
		ID:                 offer.ID,
		SessionID:          offer.SessionID,
		DriverID:           offer.DriverID,
		DriverName:         offer.DriverName,
		PlateNumber:        offer.PlateNumber,
		VehicleType:        offer.VehicleType,
		ProposedFareAmount: offer.ProposedFareAmount,
		Status:             offer.Status,
		CreatedAt:          offer.CreatedAt,
	}
}

func NewBidOfferResponses(offers []domain.BidOffer) []BidOfferResponse {
	if offers == nil {
		return nil
	}

	responses := make([]BidOfferResponse, 0, len(offers))
	for _, offer := range offers {
		responses = append(responses, NewBidOfferResponse(offer))
	}
	return responses
}

type OnlineDriverResponse struct {
	ID                    int     `json:"id"`
	UserID                int     `json:"user_id"`
	Name                  string  `json:"name"`
	VehicleType           string  `json:"vehicle_type"`
	PlateNumber           string  `json:"plate_number"`
	Rating                float64 `json:"rating"`
	OnboardPassengerCount int     `json:"onboard_passenger_count"`
}

type PublicDriverSummaryResponse struct {
	ID          int     `json:"id"`
	Name        string  `json:"name"`
	VehicleType string  `json:"vehicle_type"`
	Rating      float64 `json:"rating"`
}

func NewOnlineDriverResponses(drivers []domain.OnlineDriver) []OnlineDriverResponse {
	if drivers == nil {
		return nil
	}

	responses := make([]OnlineDriverResponse, 0, len(drivers))
	for _, driver := range drivers {
		responses = append(responses, OnlineDriverResponse{
			ID:                    driver.ID,
			UserID:                driver.UserID,
			Name:                  driver.Name,
			VehicleType:           driver.VehicleType,
			PlateNumber:           driver.PlateNumber,
			Rating:                driver.Rating,
			OnboardPassengerCount: driver.OnboardPassengerCount,
		})
	}
	return responses
}

func NewPublicDriverSummaryResponses(
	drivers []domain.PublicDriverSummary,
) []PublicDriverSummaryResponse {
	if drivers == nil {
		return nil
	}

	responses := make([]PublicDriverSummaryResponse, 0, len(drivers))
	for _, driver := range drivers {
		responses = append(responses, PublicDriverSummaryResponse{
			ID:          driver.ID,
			Name:        driver.Name,
			VehicleType: driver.VehicleType,
			Rating:      driver.Rating,
		})
	}
	return responses
}

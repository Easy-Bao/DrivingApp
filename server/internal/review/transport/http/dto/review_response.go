package dto

import "github.com/Easy-Bao/DrivingApp/server/internal/review/domain"

type ReviewResponse struct {
	ID            int     `json:"id"`
	RideID        int     `json:"ride_id"`
	DriverID      int     `json:"driver_id"`
	PassengerID   int     `json:"passenger_id"`
	PassengerName string  `json:"passenger_name,omitempty"`
	Rating        float64 `json:"rating"`
	Comment       string  `json:"comment,omitempty"`
	CreatedAt     string  `json:"created_at"`
}

type PassengerReviewResponse struct {
	ID          int     `json:"id"`
	RideID      int     `json:"ride_id"`
	DriverID    int     `json:"driver_id"`
	PassengerID int     `json:"passenger_id"`
	Rating      float64 `json:"rating"`
	Comment     string  `json:"comment,omitempty"`
	CreatedAt   string  `json:"created_at"`
}

func NewReviewResponses(reviews []domain.Review) []ReviewResponse {
	if reviews == nil {
		return nil
	}
	responses := make([]ReviewResponse, 0, len(reviews))
	for _, review := range reviews {
		responses = append(responses, NewReviewResponse(review))
	}
	return responses
}

func NewReviewResponse(review domain.Review) ReviewResponse {
	return ReviewResponse{
		ID:            review.ID,
		RideID:        review.RideID,
		DriverID:      review.DriverID,
		PassengerID:   review.PassengerID,
		PassengerName: review.PassengerName,
		Rating:        review.Rating,
		Comment:       review.Comment,
		CreatedAt:     review.CreatedAt,
	}
}

func NewPassengerReviewResponse(review domain.PassengerReview) PassengerReviewResponse {
	return PassengerReviewResponse{
		ID:          review.ID,
		RideID:      review.RideID,
		DriverID:    review.DriverID,
		PassengerID: review.PassengerID,
		Rating:      review.Rating,
		Comment:     review.Comment,
		CreatedAt:   review.CreatedAt,
	}
}

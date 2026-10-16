package http

import "github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/domain"

type SessionResponse struct {
	Success bool        `json:"success"`
	Data    SessionData `json:"data"`
}

type SessionData struct {
	User              AccountResponse `json:"user"`
	Token             string          `json:"token"`
	RefreshToken      string          `json:"refreshToken,omitempty"`
	NeedsVerification bool            `json:"needsVerification"`
	Verified          bool            `json:"verified,omitempty"`
}

type AccountResponse struct {
	ID                int         `json:"id"`
	Email             string      `json:"email"`
	Phone             string      `json:"phone"`
	Name              string      `json:"name"`
	Role              domain.Role `json:"role"`
	IsVerified        bool        `json:"isVerified"`
	VehicleType       string      `json:"vehicleType,omitempty"`
	PlateNumber       string      `json:"plateNumber,omitempty"`
	PreferredRideType string      `json:"preferred_ride_type,omitempty"`
}

func NewAccountResponse(account domain.User) AccountResponse {
	return AccountResponse{
		ID:                account.ID,
		Email:             account.Email,
		Phone:             account.Phone,
		Name:              account.Name,
		Role:              account.Role,
		IsVerified:        account.IsVerified,
		VehicleType:       account.VehicleType,
		PlateNumber:       account.PlateNumber,
		PreferredRideType: account.PreferredRideType,
	}
}

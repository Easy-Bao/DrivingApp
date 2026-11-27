package domain

import (
	"errors"
	"strings"
	"time"
)

var ErrDriverVehicleChangeWhileOnline = errors.New(
	"driver vehicle identity cannot change while online",
)

var ErrDriverAvailabilityBlocked = errors.New(
	"driver cannot go offline with an active ride",
)

var ErrProfileNotFound = errors.New("profile not found")

var ErrInvalidRole = errors.New("unsupported profile role")

var ErrEmailChangeNotAllowed = errors.New("email cannot be changed via profile update")

var ErrPhoneChangeNotAllowed = errors.New("phone cannot be changed via profile update")

type ProfilePatch struct {
	Name        *string
	Email       *string
	Phone       *string
	Address     *string
	Gender      *string
	VehicleType *string
	PlateNumber *string
}

func ApplyProfilePatch(current Profile, patch ProfilePatch) (Profile, error) {
	if patch.Email != nil && !strings.EqualFold(strings.TrimSpace(*patch.Email), strings.TrimSpace(current.Email)) {
		return Profile{}, ErrEmailChangeNotAllowed
	}
	if patch.Phone != nil && strings.TrimSpace(*patch.Phone) != strings.TrimSpace(current.Phone) {
		return Profile{}, ErrPhoneChangeNotAllowed
	}
	if patch.Name != nil {
		current.Name = *patch.Name
	}
	if patch.Address != nil {
		current.Address = *patch.Address
	}
	if patch.Gender != nil {
		current.Gender = *patch.Gender
	}
	if patch.VehicleType != nil {
		current.VehicleType = *patch.VehicleType
	}
	if patch.PlateNumber != nil {
		current.PlateNumber = *patch.PlateNumber
	}
	return current, nil
}

type Profile struct {
	ID        int
	UserID    int
	Role      string
	Name      string
	Phone     string
	Email     string
	Address   string
	Gender    string
	AvatarURL string

	VehicleType      string
	PlateNumber      string
	Rating           float64
	IsOnline         bool
	OnlineLastSeenAt *time.Time
}

package domain

import (
	"errors"
	"time"
)

var ErrDriverVehicleChangeWhileOnline = errors.New(
	"driver vehicle identity cannot change while online",
)

var ErrDriverAvailabilityBlocked = errors.New(
	"driver cannot go offline with an active ride",
)

var ErrProfileNotFound = errors.New("profile not found")

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

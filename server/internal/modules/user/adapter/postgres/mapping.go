package postgres

import (
	"errors"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/user/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database/pgutil"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/sqlc"
	"github.com/jackc/pgx/v5/pgtype"
	"strconv"
	"strings"
	"time"
)

func driverProfileFromRow(
	account databasepostgres.User,
	id int32,
	userID int32,
	name string,
	vehicleType string,
	plateNumber string,
	rating float64,
	isOnline bool,
	onlineLastSeenAtVal pgtype.Timestamptz,
) domain.Profile {
	return domain.Profile{
		ID:               int(id),
		UserID:           int(userID),
		Role:             "driver",
		Name:             name,
		Phone:            account.Phone,
		Email:            account.Email,
		VehicleType:      vehicleType,
		PlateNumber:      plateNumber,
		Rating:           rating,
		IsOnline:         isOnline,
		OnlineLastSeenAt: onlineLastSeenAt(onlineLastSeenAtVal),
	}
}

func driverProfileFromFullRow(account databasepostgres.User, profile databasepostgres.GetDriverProfileByUserIDFullRow) domain.Profile {
	return driverProfileFromRow(
		account,
		profile.ID,
		profile.UserID,
		profile.Name,
		profile.VehicleType,
		profile.PlateNumber,
		profile.Rating,
		profile.IsOnline,
		profile.OnlineLastSeenAt,
	)
}

func driverProfileFromUpdateRow(account databasepostgres.User, profile databasepostgres.UpdateDriverProfileRow) domain.Profile {
	return driverProfileFromRow(
		account,
		profile.ID,
		profile.UserID,
		profile.Name,
		profile.VehicleType,
		profile.PlateNumber,
		profile.Rating,
		profile.IsOnline,
		profile.OnlineLastSeenAt,
	)
}

func onlineLastSeenAt(value pgtype.Timestamptz) *time.Time {
	if !value.Valid {
		return nil
	}
	seenAt := value.Time
	return &seenAt
}

func passengerProfileFromPostgres(
	account databasepostgres.User,
	profile databasepostgres.PassengerProfile,
) domain.Profile {
	return domain.Profile{
		ID:        int(profile.ID),
		UserID:    int(profile.UserID),
		Role:      "passenger",
		Name:      profile.Name,
		Phone:     account.Phone,
		Email:     account.Email,
		Address:   pgutil.TextValue(profile.Address),
		Gender:    profile.Gender,
		AvatarURL: passengerAvatarURL(int(profile.UserID), pgutil.TextValue(profile.AvatarStorageKey)),
	}
}

func passengerAvatarURL(userID int, storageKey string) string {
	if userID <= 0 || strings.TrimSpace(storageKey) == "" {
		return ""
	}
	return "/api/v1/passengers/" + strconv.Itoa(userID) + "/avatar"
}

func fromPostgresNotification(item databasepostgres.Notification) (domain.Notification, error) {
	if !item.CreatedAt.Valid {
		return domain.Notification{}, errors.New("notification creation time is null")
	}
	return domain.Notification{
		ID:        int(item.ID),
		UserID:    int(item.UserID),
		Type:      item.Type,
		Title:     item.Title,
		Body:      item.Body,
		IsRead:    item.IsRead,
		CreatedAt: item.CreatedAt.Time.UTC().Format("2006-01-02T15:04:05Z07:00"),
	}, nil
}

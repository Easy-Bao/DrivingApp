package postgres

import (
	"context"
	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/ent/driverprofile"
	"github.com/Easy-Bao/DrivingApp/server/ent/notification"
	"github.com/Easy-Bao/DrivingApp/server/ent/passengerprofile"
	"github.com/Easy-Bao/DrivingApp/server/internal/users/domain"
)

type ProfileRepository struct{ client *ent.Client }

func NewProfileRepository(client *ent.Client) *ProfileRepository {
	return &ProfileRepository{client: client}
}
func (repository *ProfileRepository) Get(ctx context.Context, userID int) (domain.Profile, error) {
	if profile, err := repository.client.DriverProfile.Query().Where(driverprofile.UserIDEQ(userID)).Only(ctx); err == nil {
		return domain.Profile{ID: profile.ID, UserID: profile.UserID, Role: "driver", Name: profile.Name, VehicleType: profile.VehicleType, PlateNumber: profile.PlateNumber, Rating: profile.Rating, IsOnline: profile.IsOnline}, nil
	}
	profile, err := repository.client.PassengerProfile.Query().Where(passengerprofile.UserIDEQ(userID)).Only(ctx)
	if err != nil {
		return domain.Profile{}, err
	}
	return domain.Profile{ID: profile.ID, UserID: profile.UserID, Role: "passenger", Name: profile.Name, PreferredRideType: profile.PreferredRideType}, nil
}
func (repository *ProfileRepository) Save(ctx context.Context, profile domain.Profile) (domain.Profile, error) {
	if profile.Role == "driver" {
		updated, err := repository.client.DriverProfile.UpdateOneID(profile.ID).SetName(profile.Name).SetVehicleType(profile.VehicleType).SetPlateNumber(profile.PlateNumber).SetIsOnline(profile.IsOnline).Save(ctx)
		if err != nil {
			return domain.Profile{}, err
		}
		return domain.Profile{ID: updated.ID, UserID: updated.UserID, Role: "driver", Name: updated.Name, VehicleType: updated.VehicleType, PlateNumber: updated.PlateNumber, Rating: updated.Rating, IsOnline: updated.IsOnline}, nil
	}
	updated, err := repository.client.PassengerProfile.UpdateOneID(profile.ID).SetName(profile.Name).SetPreferredRideType(profile.PreferredRideType).Save(ctx)
	if err != nil {
		return domain.Profile{}, err
	}
	return domain.Profile{ID: updated.ID, UserID: updated.UserID, Role: "passenger", Name: updated.Name, PreferredRideType: updated.PreferredRideType}, nil
}

func (repository *ProfileRepository) Notifications(ctx context.Context, userID int) ([]domain.Notification, error) {
	items, err := repository.client.Notification.Query().Where(notification.UserIDEQ(userID)).Order(notification.ByID()).All(ctx)
	if err != nil {
		return nil, err
	}
	result := make([]domain.Notification, 0, len(items))
	for index := len(items) - 1; index >= 0; index-- {
		item := items[index]
		result = append(result, domain.Notification{ID: item.ID, UserID: item.UserID, Type: item.Type, Title: item.Title, Body: item.Body, IsRead: item.IsRead, CreatedAt: item.CreatedAt.UTC().Format("2006-01-02T15:04:05Z07:00")})
	}
	return result, nil
}

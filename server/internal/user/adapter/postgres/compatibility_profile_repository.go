package postgres

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"strings"
	"time"

	entsql "entgo.io/ent/dialect/sql"
	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/ent/driverprofile"
	"github.com/Easy-Bao/DrivingApp/server/ent/notification"
	"github.com/Easy-Bao/DrivingApp/server/ent/passengerprofile"
	"github.com/Easy-Bao/DrivingApp/server/internal/user/domain"
)

type ProfileRepository struct {
	client        *ent.Client
	avatarStorage domain.AvatarStorage
	logger        *slog.Logger
}

func NewProfileRepository(
	client *ent.Client,
	avatarStorage domain.AvatarStorage,
) *ProfileRepository {
	return &ProfileRepository{client: client, avatarStorage: avatarStorage, logger: slog.Default()}
}

func (repository *ProfileRepository) WithLogger(logger *slog.Logger) *ProfileRepository {
	if logger != nil {
		repository.logger = logger
	}
	return repository
}

func (repository *ProfileRepository) Get(ctx context.Context, userID int) (domain.Profile, error) {
	account, err := repository.client.User.Get(ctx, userID)
	if err != nil {
		return domain.Profile{}, err
	}
	profile, err := repository.client.DriverProfile.Query().Where(driverprofile.UserIDEQ(userID)).Only(ctx)
	if err == nil {
		return domain.Profile{ID: profile.ID, UserID: profile.UserID, Role: "driver", Name: profile.Name, Phone: account.Phone, Email: account.Email, VehicleType: profile.VehicleType, PlateNumber: profile.PlateNumber, Rating: profile.Rating, IsOnline: profile.IsOnline}, nil
	}
	if !ent.IsNotFound(err) {
		return domain.Profile{}, err
	}
	passengerProfile, err := repository.client.PassengerProfile.Query().Where(passengerprofile.UserIDEQ(userID)).Only(ctx)
	if err != nil {
		return domain.Profile{}, err
	}
	return passengerProfileFromEnt(account, passengerProfile), nil
}

func (repository *ProfileRepository) Save(ctx context.Context, profile domain.Profile) (domain.Profile, error) {
	account, err := repository.client.User.UpdateOneID(profile.UserID).SetName(profile.Name).SetPhone(profile.Phone).SetEmail(profile.Email).Save(ctx)
	if err != nil {
		return domain.Profile{}, err
	}
	if profile.Role == "driver" {
		updated, err := repository.client.DriverProfile.UpdateOneID(profile.ID).SetName(profile.Name).SetVehicleType(profile.VehicleType).SetPlateNumber(profile.PlateNumber).SetIsOnline(profile.IsOnline).Save(ctx)
		if err != nil {
			return domain.Profile{}, err
		}
		return domain.Profile{ID: updated.ID, UserID: updated.UserID, Role: "driver", Name: updated.Name, Phone: account.Phone, Email: account.Email, VehicleType: updated.VehicleType, PlateNumber: updated.PlateNumber, Rating: updated.Rating, IsOnline: updated.IsOnline}, nil
	}
	updated, err := repository.client.PassengerProfile.UpdateOneID(profile.ID).SetName(profile.Name).SetAddress(profile.Address).SetGender(profile.Gender).SetPreferredRideType(profile.PreferredRideType).Save(ctx)
	if err != nil {
		return domain.Profile{}, err
	}
	return passengerProfileFromEnt(account, updated), nil
}

func (repository *ProfileRepository) SaveAvatar(ctx context.Context, userID int, content []byte, contentType string) (domain.Profile, error) {
	if repository.avatarStorage == nil {
		return domain.Profile{}, domain.ErrAvatarStorageUnavailable
	}
	passengerProfile, err := repository.client.PassengerProfile.Query().
		Where(passengerprofile.UserIDEQ(userID)).
		Only(ctx)
	if ent.IsNotFound(err) {
		return domain.Profile{}, domain.ErrAvatarNotFound
	}
	if err != nil {
		return domain.Profile{}, err
	}

	storageKey, err := repository.avatarStorage.Store(ctx, content)
	if err != nil {
		return domain.Profile{}, fmt.Errorf("store passenger avatar: %w", err)
	}
	_, err = repository.client.PassengerProfile.UpdateOneID(passengerProfile.ID).
		SetAvatarStorageKey(storageKey).
		SetAvatarContentType(contentType).
		Save(ctx)
	if err != nil {
		repository.cleanupAvatar(ctx, storageKey)
		return domain.Profile{}, err
	}

	oldStorageKey := strings.TrimSpace(passengerProfile.AvatarStorageKey)
	if oldStorageKey != "" && oldStorageKey != storageKey {
		repository.cleanupAvatar(ctx, oldStorageKey)
	}
	return repository.Get(ctx, userID)
}

func (repository *ProfileRepository) cleanupAvatar(ctx context.Context, storageKey string) {
	cleanupContext, cancel := context.WithTimeout(context.WithoutCancel(ctx), time.Second)
	defer cancel()
	if err := repository.avatarStorage.Delete(cleanupContext, storageKey); err != nil {
		repository.logger.WarnContext(ctx, "delete passenger avatar object failed", "error", err, "operation", "delete")
	}
}

func (repository *ProfileRepository) GetAvatar(ctx context.Context, userID int) (domain.Avatar, error) {
	if repository.avatarStorage == nil {
		return domain.Avatar{}, domain.ErrAvatarStorageUnavailable
	}
	passengerProfile, err := repository.client.PassengerProfile.Query().
		Where(passengerprofile.UserIDEQ(userID)).
		Only(ctx)
	if ent.IsNotFound(err) {
		return domain.Avatar{}, domain.ErrAvatarNotFound
	}
	if err != nil {
		return domain.Avatar{}, err
	}
	storageKey := strings.TrimSpace(passengerProfile.AvatarStorageKey)
	if storageKey == "" {
		return domain.Avatar{}, domain.ErrAvatarNotFound
	}
	content, err := repository.avatarStorage.Read(ctx, storageKey, domain.MaxAvatarBytes)
	if err != nil {
		return domain.Avatar{}, fmt.Errorf("read passenger avatar: %w", domain.ErrAvatarCorrupt)
	}
	contentType := http.DetectContentType(content)
	if (contentType != "image/jpeg" && contentType != "image/png") ||
		(passengerProfile.AvatarContentType != "" && passengerProfile.AvatarContentType != contentType) {
		return domain.Avatar{}, domain.ErrAvatarCorrupt
	}
	return domain.Avatar{Bytes: content, ContentType: contentType}, nil
}

func passengerProfileFromEnt(account *ent.User, profile *ent.PassengerProfile) domain.Profile {
	return domain.Profile{
		ID:                profile.ID,
		UserID:            profile.UserID,
		Role:              "passenger",
		Name:              profile.Name,
		Phone:             account.Phone,
		Email:             account.Email,
		Address:           profile.Address,
		Gender:            profile.Gender,
		AvatarURL:         passengerAvatarURL(profile.UserID, profile.AvatarStorageKey),
		PreferredRideType: profile.PreferredRideType,
	}
}

func passengerAvatarURL(userID int, storageKey string) string {
	if userID <= 0 || strings.TrimSpace(storageKey) == "" {
		return ""
	}
	return fmt.Sprintf("/api/v1/passengers/%d/avatar", userID)
}

func (repository *ProfileRepository) Notifications(ctx context.Context, userID, limit, offset int) ([]domain.Notification, error) {
	items, err := repository.client.Notification.Query().
		Where(notification.UserIDEQ(userID)).
		Order(notification.ByID(entsql.OrderDesc())).
		Limit(limit + 1).
		Offset(offset).
		All(ctx)
	if err != nil {
		return nil, err
	}
	result := make([]domain.Notification, 0, len(items))
	for _, item := range items {
		result = append(result, domain.Notification{ID: item.ID, UserID: item.UserID, Type: item.Type, Title: item.Title, Body: item.Body, IsRead: item.IsRead, CreatedAt: item.CreatedAt.UTC().Format("2006-01-02T15:04:05Z07:00")})
	}
	return result, nil
}

func (repository *ProfileRepository) DeleteNotification(
	ctx context.Context,
	userID int,
	notificationID int,
) error {
	deleted, err := repository.client.Notification.Delete().
		Where(
			notification.IDEQ(notificationID),
			notification.UserIDEQ(userID),
		).
		Exec(ctx)
	if err != nil {
		return err
	}
	if deleted == 0 {
		return domain.ErrNotificationNotFound
	}
	return nil
}

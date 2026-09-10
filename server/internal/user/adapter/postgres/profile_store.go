package postgres

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"strings"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	platformstorage "github.com/Easy-Bao/DrivingApp/server/internal/platform/storage"
	"github.com/Easy-Bao/DrivingApp/server/internal/user/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/user/ports"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

const maxPostgresProfileID = 1<<31 - 1

// ProfileRepository persists user profiles and notifications through the
// generated queries.
type ProfileRepository struct {
	pool          *pgxpool.Pool
	queries       *databasepostgres.Queries
	avatarStorage platformstorage.ObjectStore
	logger        *slog.Logger
}

var (
	_ ports.ProfileStore      = (*ProfileRepository)(nil)
	_ ports.AvatarStore       = (*ProfileRepository)(nil)
	_ ports.NotificationStore = (*ProfileRepository)(nil)
)

func NewProfileRepository(
	pool *pgxpool.Pool,
	avatarStorage platformstorage.ObjectStore,
) (*ProfileRepository, error) {
	if pool == nil {
		return nil, errors.New("postgresql pool is required")
	}
	return &ProfileRepository{
		pool:          pool,
		queries:       databasepostgres.New(pool),
		avatarStorage: avatarStorage,
		logger:        slog.Default(),
	}, nil
}

// ProfileStore is the canonical adapter name used by the user composition
// root. The repository constructor remains for existing internal callers.
type ProfileStore = ProfileRepository

func NewProfileStore(
	pool *pgxpool.Pool,
	avatarStorage platformstorage.ObjectStore,
) (*ProfileStore, error) {
	return NewProfileRepository(pool, avatarStorage)
}

func (repository *ProfileRepository) WithLogger(logger *slog.Logger) *ProfileRepository {
	if logger != nil {
		repository.logger = logger
	}
	return repository
}

func (repository *ProfileRepository) Get(ctx context.Context, userID int) (domain.Profile, error) {
	if err := repository.validate(); err != nil {
		return domain.Profile{}, err
	}
	dbUserID, err := toPostgresProfileID(userID, "user id")
	if err != nil {
		return domain.Profile{}, err
	}

	account, err := repository.queries.GetUserByID(ctx, dbUserID)
	if err != nil {
		return domain.Profile{}, fmt.Errorf("find profile account: %w", err)
	}

	driverProfile, err := repository.queries.GetDriverProfileByUserIDFull(ctx, dbUserID)
	if err == nil {
		return driverProfileFromPostgres(account, driverProfile), nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return domain.Profile{}, fmt.Errorf("find driver profile: %w", err)
	}

	passengerProfile, err := repository.queries.GetPassengerProfileByUserIDFull(ctx, dbUserID)
	if err != nil {
		return domain.Profile{}, fmt.Errorf("find passenger profile: %w", err)
	}
	return passengerProfileFromPostgres(account, passengerProfile), nil
}

func (repository *ProfileRepository) Save(ctx context.Context, profile domain.Profile) (domain.Profile, error) {
	if err := repository.validate(); err != nil {
		return domain.Profile{}, err
	}
	if profile.Role != "driver" && profile.Role != "passenger" {
		return domain.Profile{}, fmt.Errorf("unsupported profile role %q", profile.Role)
	}
	dbUserID, err := toPostgresProfileID(profile.UserID, "user id")
	if err != nil {
		return domain.Profile{}, err
	}
	dbProfileID, err := toPostgresProfileID(profile.ID, "profile id")
	if err != nil {
		return domain.Profile{}, err
	}

	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.Profile{}, fmt.Errorf("begin profile update transaction: %w", err)
	}
	defer func() {
		_ = transaction.Rollback(ctx)
	}()

	transactionQueries := repository.queries.WithTx(transaction)
	account, err := transactionQueries.UpdateUserProfile(ctx, databasepostgres.UpdateUserProfileParams{
		ID:    dbUserID,
		Name:  toPostgresProfileText(profile.Name),
		Phone: profile.Phone,
		Email: profile.Email,
	})
	if err != nil {
		return domain.Profile{}, fmt.Errorf("update profile account: %w", err)
	}

	var updated domain.Profile
	switch profile.Role {
	case "driver":
		driverProfile, updateErr := transactionQueries.UpdateDriverProfile(ctx, databasepostgres.UpdateDriverProfileParams{
			ID:          dbProfileID,
			Name:        profile.Name,
			VehicleType: profile.VehicleType,
			PlateNumber: profile.PlateNumber,
			IsOnline:    profile.IsOnline,
		})
		if updateErr != nil {
			return domain.Profile{}, fmt.Errorf("update driver profile: %w", updateErr)
		}
		updated = driverProfileFromPostgres(account, driverProfile)
	case "passenger":
		passengerProfile, updateErr := transactionQueries.UpdatePassengerProfile(ctx, databasepostgres.UpdatePassengerProfileParams{
			ID:                dbProfileID,
			Name:              profile.Name,
			Address:           toPostgresProfileText(profile.Address),
			Gender:            profile.Gender,
			PreferredRideType: toPostgresProfileText(profile.PreferredRideType),
		})
		if updateErr != nil {
			return domain.Profile{}, fmt.Errorf("update passenger profile: %w", updateErr)
		}
		updated = passengerProfileFromPostgres(account, passengerProfile)
	}

	if err := transaction.Commit(ctx); err != nil {
		return domain.Profile{}, fmt.Errorf("commit profile update transaction: %w", err)
	}
	return updated, nil
}

func (repository *ProfileRepository) SaveAvatar(
	ctx context.Context,
	userID int,
	content []byte,
	contentType string,
) (domain.Profile, error) {
	if err := repository.validate(); err != nil {
		return domain.Profile{}, err
	}
	if repository.avatarStorage == nil {
		return domain.Profile{}, domain.ErrAvatarStorageUnavailable
	}
	dbUserID, err := toPostgresProfileID(userID, "user id")
	if err != nil {
		return domain.Profile{}, err
	}

	passengerProfile, err := repository.queries.GetPassengerProfileByUserIDFull(ctx, dbUserID)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Profile{}, domain.ErrAvatarNotFound
	}
	if err != nil {
		return domain.Profile{}, fmt.Errorf("find passenger avatar profile: %w", err)
	}

	storageKey, err := repository.avatarStorage.Store(ctx, content)
	if err != nil {
		return domain.Profile{}, fmt.Errorf("store passenger avatar: %w", err)
	}
	updatedRows, err := repository.queries.UpdatePassengerAvatar(ctx, databasepostgres.UpdatePassengerAvatarParams{
		ID:                passengerProfile.ID,
		AvatarStorageKey:  toPostgresProfileText(storageKey),
		AvatarContentType: toPostgresProfileText(contentType),
	})
	if err != nil {
		repository.cleanupAvatar(ctx, storageKey)
		return domain.Profile{}, fmt.Errorf("update passenger avatar metadata: %w", err)
	}
	if updatedRows == 0 {
		repository.cleanupAvatar(ctx, storageKey)
		return domain.Profile{}, domain.ErrAvatarNotFound
	}

	oldStorageKey := strings.TrimSpace(profileTextValue(passengerProfile.AvatarStorageKey))
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
	if err := repository.validate(); err != nil {
		return domain.Avatar{}, err
	}
	if repository.avatarStorage == nil {
		return domain.Avatar{}, domain.ErrAvatarStorageUnavailable
	}
	dbUserID, err := toPostgresProfileID(userID, "user id")
	if err != nil {
		return domain.Avatar{}, err
	}

	passengerProfile, err := repository.queries.GetPassengerProfileByUserIDFull(ctx, dbUserID)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Avatar{}, domain.ErrAvatarNotFound
	}
	if err != nil {
		return domain.Avatar{}, fmt.Errorf("find passenger avatar profile: %w", err)
	}
	storageKey := strings.TrimSpace(profileTextValue(passengerProfile.AvatarStorageKey))
	if storageKey == "" {
		return domain.Avatar{}, domain.ErrAvatarNotFound
	}

	content, err := repository.avatarStorage.Read(ctx, storageKey, domain.MaxAvatarBytes)
	if err != nil {
		return domain.Avatar{}, fmt.Errorf("read passenger avatar: %w", domain.ErrAvatarCorrupt)
	}
	contentType := http.DetectContentType(content)
	storedContentType := strings.TrimSpace(profileTextValue(passengerProfile.AvatarContentType))
	if (contentType != "image/jpeg" && contentType != "image/png") ||
		(storedContentType != "" && storedContentType != contentType) {
		return domain.Avatar{}, domain.ErrAvatarCorrupt
	}
	return domain.Avatar{Bytes: content, ContentType: contentType}, nil
}

func (repository *ProfileRepository) Notifications(
	ctx context.Context,
	userID int,
	limit int,
	offset int,
) ([]domain.Notification, error) {
	if err := repository.validate(); err != nil {
		return nil, err
	}
	dbUserID, err := toPostgresProfileID(userID, "user id")
	if err != nil {
		return nil, err
	}
	if limit <= 0 {
		return nil, errors.New("notification limit must be positive")
	}
	if limit == int(^uint(0)>>1) {
		return nil, errors.New("notification limit exceeds native integer range")
	}
	dbLimit, err := toPostgresProfilePageValue(limit+1, "limit")
	if err != nil {
		return nil, err
	}
	dbOffset, err := toPostgresProfilePageValue(offset, "offset")
	if err != nil {
		return nil, err
	}

	items, err := repository.queries.ListNotifications(ctx, databasepostgres.ListNotificationsParams{
		UserID: dbUserID,
		Limit:  dbLimit,
		Offset: dbOffset,
	})
	if err != nil {
		return nil, fmt.Errorf("list notifications: %w", err)
	}
	result := make([]domain.Notification, 0, len(items))
	for _, item := range items {
		notification, mappingErr := fromPostgresNotification(item)
		if mappingErr != nil {
			return nil, mappingErr
		}
		result = append(result, notification)
	}
	return result, nil
}

func (repository *ProfileRepository) DeleteNotification(
	ctx context.Context,
	userID int,
	notificationID int,
) error {
	if err := repository.validate(); err != nil {
		return err
	}
	dbUserID, err := toPostgresProfileID(userID, "user id")
	if err != nil {
		return err
	}
	dbNotificationID, err := toPostgresProfileID(notificationID, "notification id")
	if err != nil {
		return err
	}
	deleted, err := repository.queries.DeleteNotification(ctx, databasepostgres.DeleteNotificationParams{
		ID:     dbNotificationID,
		UserID: dbUserID,
	})
	if err != nil {
		return fmt.Errorf("delete notification: %w", err)
	}
	if deleted == 0 {
		return domain.ErrNotificationNotFound
	}
	return nil
}

func (repository *ProfileRepository) validate() error {
	if repository == nil || repository.pool == nil || repository.queries == nil {
		return errors.New("postgresql profile repository is not initialized")
	}
	return nil
}

func driverProfileFromPostgres(account databasepostgres.User, profile databasepostgres.DriverProfile) domain.Profile {
	return domain.Profile{
		ID:          int(profile.ID),
		UserID:      int(profile.UserID),
		Role:        "driver",
		Name:        profile.Name,
		Phone:       account.Phone,
		Email:       account.Email,
		VehicleType: profile.VehicleType,
		PlateNumber: profile.PlateNumber,
		Rating:      profile.Rating,
		IsOnline:    profile.IsOnline,
	}
}

func passengerProfileFromPostgres(account databasepostgres.User, profile databasepostgres.PassengerProfile) domain.Profile {
	return domain.Profile{
		ID:                int(profile.ID),
		UserID:            int(profile.UserID),
		Role:              "passenger",
		Name:              profile.Name,
		Phone:             account.Phone,
		Email:             account.Email,
		Address:           profileTextValue(profile.Address),
		Gender:            profile.Gender,
		AvatarURL:         passengerAvatarURL(int(profile.UserID), profileTextValue(profile.AvatarStorageKey)),
		PreferredRideType: profileTextValue(profile.PreferredRideType),
	}
}

func passengerAvatarURL(userID int, storageKey string) string {
	if userID <= 0 || strings.TrimSpace(storageKey) == "" {
		return ""
	}
	return fmt.Sprintf("/api/v1/passengers/%d/avatar", userID)
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

func toPostgresProfileID(value int, field string) (int32, error) {
	if value <= 0 || int64(value) > int64(maxPostgresProfileID) {
		return 0, fmt.Errorf("%s %d is outside PostgreSQL integer range", field, value)
	}
	return int32(value), nil
}

func toPostgresProfilePageValue(value int, field string) (int32, error) {
	if value < 0 || int64(value) > int64(maxPostgresProfileID) {
		return 0, fmt.Errorf("%s %d is outside PostgreSQL integer range", field, value)
	}
	return int32(value), nil
}

func toPostgresProfileText(value string) pgtype.Text {
	return pgtype.Text{String: value, Valid: true}
}

func profileTextValue(value pgtype.Text) string {
	if !value.Valid {
		return ""
	}
	return value.String
}

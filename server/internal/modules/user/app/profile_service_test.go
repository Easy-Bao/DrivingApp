package app_test

import (
	"context"
	"errors"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/user/app"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/user/domain"
)

type repository struct{ profile domain.Profile }

func newProfileService(
	repository app.ProfileStore,
	options ...app.ProfileServiceOption,
) *app.ProfileService {
	return app.NewProfileService(
		app.ProfileServiceDependencies{Repository: repository},
		options...,
	)
}

func (r *repository) Get(context.Context, int) (domain.Profile, error) { return r.profile, nil }
func (r *repository) Save(_ context.Context, profile domain.Profile) (domain.Profile, error) {
	r.profile = profile
	return profile, nil
}
func (r *repository) Patch(_ context.Context, _ int, patch domain.ProfilePatch) (domain.Profile, error) {
	updated, err := domain.ApplyProfilePatch(r.profile, patch)
	if err != nil {
		return domain.Profile{}, err
	}
	r.profile = updated
	return updated, nil
}
func (r *repository) UpdateOnlineStatus(
	_ context.Context,
	userID int,
	targetID int,
	isOnline bool,
) (domain.Profile, error) {
	r.profile.UserID = userID
	r.profile.ID = targetID
	r.profile.IsOnline = isOnline
	return r.profile, nil
}

func (r *repository) SaveAvatar(
	context.Context,
	int,
	[]byte,
	string,
) (domain.Profile, error) {
	return r.profile, nil
}

func (*repository) GetAvatar(context.Context, int) (domain.Avatar, error) {
	return domain.Avatar{}, errors.New("avatar not found")
}
func TestProfileUpdateUsesTheDomainService(t *testing.T) {
	service := newProfileService(&repository{})
	profile, err := service.Update(context.Background(), domain.Profile{UserID: 4, Role: "driver", Name: "Bao Bao Driver"})
	if err != nil || profile.UserID != 4 {
		t.Fatalf("profile update = %#v, %v", profile, err)
	}
}

func TestProfilePatchPreservesOmittedFields(t *testing.T) {
	repo := &repository{
		profile: domain.Profile{
			UserID:  4,
			Role:    "passenger",
			Name:    "Before",
			Email:   "before@example.test",
			Phone:   "+639171111111",
			Address: "Original Address",
			Gender:  "Female",
		},
	}
	service := newProfileService(repo)
	newName := "After"
	updated, err := service.Patch(context.Background(), 4, domain.ProfilePatch{Name: &newName})
	if err != nil {
		t.Fatalf("Patch() error = %v", err)
	}
	if updated.Name != "After" || updated.Address != "Original Address" || updated.Gender != "Female" {
		t.Fatalf("patched profile lost omitted fields: %#v", updated)
	}
	badEmail := "other@example.test"
	if _, err := service.Patch(context.Background(), 4, domain.ProfilePatch{Email: &badEmail}); !errors.Is(err, domain.ErrEmailChangeNotAllowed) {
		t.Fatalf("Patch(email change) = %v, want ErrEmailChangeNotAllowed", err)
	}
	badPhone := "+639179999999"
	if _, err := service.Patch(context.Background(), 4, domain.ProfilePatch{Phone: &badPhone}); !errors.Is(err, domain.ErrPhoneChangeNotAllowed) {
		t.Fatalf("Patch(phone change) = %v, want ErrPhoneChangeNotAllowed", err)
	}
}

func TestProfileAvatarUsesInjectedContentTypeDetector(t *testing.T) {
	service := newProfileService(
		&repository{},
		app.WithContentTypeDetector(func([]byte) string { return "image/png" }),
	)
	if _, err := service.SaveAvatar(context.Background(), 4, []byte("avatar")); err != nil {
		t.Fatalf("SaveAvatar() error = %v", err)
	}
}

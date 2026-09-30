package application_test

import (
	"context"
	"errors"
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/user/application"
	"github.com/Easy-Bao/DrivingApp/server/internal/user/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/user/ports"
)

type repository struct{ profile domain.Profile }

func newProfileService(
	repository ports.ProfileStore,
	options ...application.ProfileServiceOption,
) *application.ProfileService {
	return application.NewProfileService(
		application.ProfileServiceDependencies{Repository: repository},
		options...,
	)
}

func (r *repository) Get(context.Context, int) (domain.Profile, error) { return r.profile, nil }
func (r *repository) Save(_ context.Context, profile domain.Profile) (domain.Profile, error) {
	r.profile = profile
	return profile, nil
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

func TestProfileAvatarUsesInjectedContentTypeDetector(t *testing.T) {
	service := newProfileService(
		&repository{},
		application.WithContentTypeDetector(func([]byte) string { return "image/png" }),
	)
	if _, err := service.SaveAvatar(context.Background(), 4, []byte("avatar")); err != nil {
		t.Fatalf("SaveAvatar() error = %v", err)
	}
}

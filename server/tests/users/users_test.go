package users_test

import (
	"context"
	"github.com/Easy-Bao/DrivingApp/server/internal/users/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/users/usecase"
	"testing"
)

type repository struct{ profile domain.Profile }

func (r *repository) Get(context.Context, int) (domain.Profile, error) { return r.profile, nil }
func (r *repository) Save(_ context.Context, profile domain.Profile) (domain.Profile, error) {
	r.profile = profile
	return profile, nil
}
func TestProfileUpdateUsesTheDomainService(t *testing.T) {
	service := usecase.NewProfileService(&repository{})
	profile, err := service.Update(context.Background(), domain.Profile{UserID: 4, Role: "driver", Name: "Bao Bao Driver"})
	if err != nil || profile.UserID != 4 {
		t.Fatalf("profile update = %#v, %v", profile, err)
	}
}

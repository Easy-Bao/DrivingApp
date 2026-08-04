package usecase

import (
	"context"
	"strings"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
)

type RegisterInput struct {
	Email       string
	Phone       string
	Name        string
	Password    string
	VehicleType string
	PlateNumber string
}

type RegisterService struct {
	repository  domain.UserRepository
	tokens      domain.TokenIssuer
	provisioner domain.ProfileProvisioner
}

func NewRegisterService(repository domain.UserRepository, tokens domain.TokenIssuer, provisioners ...domain.ProfileProvisioner) *RegisterService {
	var provisioner domain.ProfileProvisioner
	if len(provisioners) > 0 {
		provisioner = provisioners[0]
	}
	return &RegisterService{repository: repository, tokens: tokens, provisioner: provisioner}
}

func (service *RegisterService) Passenger(ctx context.Context, input RegisterInput) (domain.User, string, error) {
	return service.register(ctx, input, domain.Passenger)
}

func (service *RegisterService) Driver(ctx context.Context, input RegisterInput) (domain.User, string, error) {
	return service.register(ctx, input, domain.Driver)
}

func (service *RegisterService) register(ctx context.Context, input RegisterInput, role domain.Role) (domain.User, string, error) {
	if strings.TrimSpace(input.Email) == "" || input.Password == "" {
		return domain.User{}, "", domain.ErrInvalidCredentials
	}
	if existing, err := service.repository.FindByEmail(ctx, strings.ToLower(strings.TrimSpace(input.Email))); err == nil && existing.ID != 0 {
		return domain.User{}, "", domain.ErrEmailTaken
	}
	account, err := service.repository.Create(ctx, domain.User{
		Email:             strings.ToLower(strings.TrimSpace(input.Email)),
		Phone:             strings.TrimSpace(input.Phone),
		Name:              strings.TrimSpace(input.Name),
		Role:              role,
		PasswordHash:      HashPassword(input.Password),
		VehicleType:       strings.TrimSpace(input.VehicleType),
		PlateNumber:       strings.TrimSpace(input.PlateNumber),
		PreferredRideType: "solo-ride",
	})
	if err != nil {
		return domain.User{}, "", err
	}
	if service.provisioner != nil {
		if err := service.provisioner.Provision(ctx, account); err != nil {
			return domain.User{}, "", err
		}
	}
	token, err := service.tokens.Issue(intSubject(account.ID))
	return account, token, err
}

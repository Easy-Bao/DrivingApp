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

func (service *RegisterService) PreparePassenger(ctx context.Context, input RegisterInput) (domain.PendingRegistration, error) {
	normalized, err := normalizeInput(input, domain.Passenger)
	if err != nil {
		return domain.PendingRegistration{}, err
	}
	if existing, err := service.repository.FindByEmail(ctx, normalized.Email); err == nil && existing.ID != 0 {
		return domain.PendingRegistration{}, domain.ErrEmailTaken
	}
	return domain.PendingRegistration{
		Email:             normalized.Email,
		Phone:             normalized.Phone,
		Name:              normalized.Name,
		PasswordHash:      normalized.PasswordHash,
		Role:              normalized.Role,
		VehicleType:       normalized.VehicleType,
		PlateNumber:       normalized.PlateNumber,
		PreferredRideType: normalized.PreferredRideType,
	}, nil
}

func (service *RegisterService) CommitPendingPassenger(ctx context.Context, pending domain.PendingRegistration) (domain.User, string, error) {
	if pending.Role != domain.Passenger || pending.Email == "" || pending.PasswordHash == "" {
		return domain.User{}, "", domain.ErrInvalidCredentials
	}
	if existing, err := service.repository.FindByEmail(ctx, pending.Email); err == nil && existing.ID != 0 {
		return domain.User{}, "", domain.ErrEmailTaken
	}
	return service.create(ctx, domain.User{
		Email:             pending.Email,
		Phone:             pending.Phone,
		Name:              pending.Name,
		Role:              pending.Role,
		PasswordHash:      pending.PasswordHash,
		IsVerified:        true,
		VehicleType:       pending.VehicleType,
		PlateNumber:       pending.PlateNumber,
		PreferredRideType: pending.PreferredRideType,
	})
}

func (service *RegisterService) register(ctx context.Context, input RegisterInput, role domain.Role) (domain.User, string, error) {
	normalized, err := normalizeInput(input, role)
	if err != nil {
		return domain.User{}, "", err
	}
	if existing, err := service.repository.FindByEmail(ctx, normalized.Email); err == nil && existing.ID != 0 {
		return domain.User{}, "", domain.ErrEmailTaken
	}
	return service.create(ctx, domain.User{
		Email:             normalized.Email,
		Phone:             normalized.Phone,
		Name:              normalized.Name,
		Role:              normalized.Role,
		PasswordHash:      normalized.PasswordHash,
		VehicleType:       normalized.VehicleType,
		PlateNumber:       normalized.PlateNumber,
		PreferredRideType: normalized.PreferredRideType,
	})
}

type normalizedRegistration struct {
	Email             string
	Phone             string
	Name              string
	PasswordHash      string
	Role              domain.Role
	VehicleType       string
	PlateNumber       string
	PreferredRideType string
}

func normalizeInput(input RegisterInput, role domain.Role) (normalizedRegistration, error) {
	if strings.TrimSpace(input.Email) == "" || len(input.Password) < 8 || len([]byte(input.Password)) > 72 {
		return normalizedRegistration{}, domain.ErrInvalidCredentials
	}
	passwordHash, err := HashPasswordWithError(input.Password)
	if err != nil {
		return normalizedRegistration{}, domain.ErrInvalidCredentials
	}
	return normalizedRegistration{
		Email:             strings.ToLower(strings.TrimSpace(input.Email)),
		Phone:             strings.TrimSpace(input.Phone),
		Name:              strings.TrimSpace(input.Name),
		PasswordHash:      passwordHash,
		Role:              role,
		VehicleType:       strings.TrimSpace(input.VehicleType),
		PlateNumber:       strings.TrimSpace(input.PlateNumber),
		PreferredRideType: "solo-ride",
	}, nil
}

func (service *RegisterService) create(ctx context.Context, account domain.User) (domain.User, string, error) {
	created, err := service.repository.Create(ctx, account)
	if err != nil {
		return domain.User{}, "", err
	}
	if service.provisioner != nil {
		if err := service.provisioner.Provision(ctx, created); err != nil {
			return domain.User{}, "", err
		}
	}
	token, err := issueToken(service.tokens, intSubject(created.ID), created.Role)
	return created, token, err
}

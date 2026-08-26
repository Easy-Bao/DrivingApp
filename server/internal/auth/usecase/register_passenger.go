package usecase

import (
	"context"
	"net/mail"
	"regexp"
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
	repository domain.UserRepository
	tokens     domain.TokenIssuer
	sessions   domain.RefreshSessionStore
}

func NewRegisterService(repository domain.UserRepository, tokens domain.TokenIssuer, sessions domain.RefreshSessionStore) *RegisterService {
	return &RegisterService{repository: repository, tokens: tokens, sessions: sessions}
}

func (service *RegisterService) Passenger(ctx context.Context, input RegisterInput) (domain.User, string, error) {
	return service.register(ctx, input, domain.Passenger)
}

func (service *RegisterService) Driver(ctx context.Context, input RegisterInput) (domain.User, string, error) {
	return service.register(ctx, input, domain.Driver)
}

func (service *RegisterService) IssueRefreshToken(ctx context.Context, account domain.User) (string, error) {
	return issueRefreshToken(ctx, service.sessions, intSubject(account.ID), account.Role)
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
	email := strings.ToLower(strings.TrimSpace(input.Email))
	name := strings.TrimSpace(input.Name)
	phone := strings.TrimSpace(input.Phone)
	vehicleType := strings.TrimSpace(input.VehicleType)
	plateNumber := strings.TrimSpace(input.PlateNumber)
	if !validEmail(email) || name == "" || len([]rune(name)) > 100 || !e164Phone.MatchString(phone) || len(input.Password) < 8 || len([]byte(input.Password)) > 72 {
		return normalizedRegistration{}, domain.ErrInvalidCredentials
	}
	if role == domain.Driver && (vehicleType == "" || plateNumber == "" || len([]rune(vehicleType)) > 80 || len([]rune(plateNumber)) > 32) {
		return normalizedRegistration{}, domain.ErrInvalidCredentials
	}
	passwordHash, err := HashPasswordWithError(input.Password)
	if err != nil {
		return normalizedRegistration{}, domain.ErrInvalidCredentials
	}
	return normalizedRegistration{
		Email:             email,
		Phone:             phone,
		Name:              name,
		PasswordHash:      passwordHash,
		Role:              role,
		VehicleType:       vehicleType,
		PlateNumber:       plateNumber,
		PreferredRideType: "solo-ride",
	}, nil
}

func (service *RegisterService) create(ctx context.Context, account domain.User) (domain.User, string, error) {
	created, err := service.repository.Create(ctx, account)
	if err != nil {
		return domain.User{}, "", err
	}
	token, err := issueToken(service.tokens, intSubject(created.ID), created.Role)
	return created, token, err
}

var e164Phone = regexp.MustCompile(`^\+[1-9][0-9]{7,14}$`)

func validEmail(value string) bool {
	if value == "" || len(value) > 254 {
		return false
	}
	address, err := mail.ParseAddress(value)
	return err == nil && strings.EqualFold(address.Address, value)
}

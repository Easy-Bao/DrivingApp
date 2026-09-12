package application

import (
	"context"
	"errors"
	"fmt"
	"net/mail"
	"regexp"
	"strings"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	authports "github.com/Easy-Bao/DrivingApp/server/internal/auth/ports"
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
	repository authports.UserStore
	tokens     authports.TokenIssuer
	sessions   authports.SessionStore
}

var ErrRegistrationUnavailable = errors.New("registration is unavailable")

func NewRegisterService(
	repository authports.UserStore,
	tokens authports.TokenIssuer,
	sessions authports.SessionStore,
) *RegisterService {
	return &RegisterService{repository: repository, tokens: tokens, sessions: sessions}
}

func (service *RegisterService) Passenger(ctx context.Context, input RegisterInput) (domain.User, string, error) {
	return service.register(ctx, input, domain.Passenger)
}

func (service *RegisterService) Driver(ctx context.Context, input RegisterInput) (domain.User, string, error) {
	return service.register(ctx, input, domain.Driver)
}

func (service *RegisterService) IssueRefreshToken(ctx context.Context, account domain.User) (string, error) {
	if service == nil {
		return "", ErrRegistrationUnavailable
	}
	return issueRefreshToken(
		ctx,
		service.sessions,
		intSubject(account.ID),
		account.Role,
	)
}

func (service *RegisterService) PreparePassenger(
	ctx context.Context,
	input RegisterInput,
) (domain.PendingRegistration, error) {
	if service == nil || service.repository == nil {
		return domain.PendingRegistration{}, ErrRegistrationUnavailable
	}
	normalized, err := normalizeInput(input, domain.Passenger)
	if err != nil {
		return domain.PendingRegistration{}, fmt.Errorf("normalize passenger registration input: %w", err)
	}
	existing, err := service.repository.FindByEmail(ctx, normalized.Email)
	if err == nil && existing.ID != 0 {
		return domain.PendingRegistration{}, domain.ErrEmailTaken
	}
	if err != nil && !errors.Is(err, domain.ErrUserNotFound) {
		return domain.PendingRegistration{}, fmt.Errorf("check existing passenger account: %w", err)
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

func (service *RegisterService) CommitPendingPassenger(
	ctx context.Context,
	pending domain.PendingRegistration,
) (domain.User, string, error) {
	if service == nil || service.repository == nil {
		return domain.User{}, "", ErrRegistrationUnavailable
	}
	invalidRole := pending.Role != domain.Passenger
	missingEmail := pending.Email == ""
	missingPasswordHash := pending.PasswordHash == ""
	if invalidRole || missingEmail || missingPasswordHash {
		return domain.User{}, "", domain.ErrInvalidCredentials
	}
	existing, err := service.repository.FindByEmail(ctx, pending.Email)
	if err == nil && existing.ID != 0 {
		return domain.User{}, "", domain.ErrEmailTaken
	}
	if err != nil && !errors.Is(err, domain.ErrUserNotFound) {
		return domain.User{}, "", fmt.Errorf("check existing passenger account: %w", err)
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

func (service *RegisterService) register(
	ctx context.Context,
	input RegisterInput,
	role domain.Role,
) (domain.User, string, error) {
	if service == nil || service.repository == nil {
		return domain.User{}, "", ErrRegistrationUnavailable
	}
	normalized, err := normalizeInput(input, role)
	if err != nil {
		return domain.User{}, "", fmt.Errorf("normalize registration input: %w", err)
	}
	existing, err := service.repository.FindByEmail(ctx, normalized.Email)
	if err == nil && existing.ID != 0 {
		return domain.User{}, "", domain.ErrEmailTaken
	}
	if err != nil && !errors.Is(err, domain.ErrUserNotFound) {
		return domain.User{}, "", fmt.Errorf("check existing account: %w", err)
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
	invalidEmail := !validEmail(email)
	invalidName := name == "" || len([]rune(name)) > 100
	invalidPhone := !e164Phone.MatchString(phone)
	invalidPassword := len(input.Password) < 8 || len([]byte(input.Password)) > 72
	if invalidEmail || invalidName || invalidPhone || invalidPassword {
		return normalizedRegistration{}, domain.ErrInvalidCredentials
	}
	invalidVehicleType := vehicleType == "" || len([]rune(vehicleType)) > 80
	invalidPlateNumber := plateNumber == "" || len([]rune(plateNumber)) > 32
	if role == domain.Driver && (invalidVehicleType || invalidPlateNumber) {
		return normalizedRegistration{}, domain.ErrInvalidCredentials
	}
	passwordHash, err := HashPasswordWithError(input.Password)
	if err != nil {
		return normalizedRegistration{}, fmt.Errorf("hash registration password: %w", err)
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
	if service == nil || service.repository == nil {
		return domain.User{}, "", ErrRegistrationUnavailable
	}
	created, err := service.repository.Create(ctx, account)
	if err != nil {
		return domain.User{}, "", fmt.Errorf("create account: %w", err)
	}
	token, err := issueToken(service.tokens, intSubject(created.ID), created.Role)
	if err != nil {
		return domain.User{}, "", fmt.Errorf("issue account token: %w", err)
	}
	return created, token, nil
}

var e164Phone = regexp.MustCompile(`^\+[1-9][0-9]{7,14}$`)

func validEmail(value string) bool {
	if value == "" || len(value) > 254 {
		return false
	}
	address, err := mail.ParseAddress(value)
	return err == nil && strings.EqualFold(address.Address, value)
}

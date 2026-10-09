package verification_test

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	authpassword "github.com/Easy-Bao/DrivingApp/server/internal/auth/password"
	authports "github.com/Easy-Bao/DrivingApp/server/internal/auth/ports"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/verification"
)

type emailChangeUsers struct {
	accounts map[int]domain.User
}

func (store *emailChangeUsers) Create(_ context.Context, account domain.User) (domain.User, error) {
	store.accounts[account.ID] = account
	return account, nil
}

func (store *emailChangeUsers) FindByEmail(_ context.Context, email string) (domain.User, error) {
	for _, account := range store.accounts {
		if strings.EqualFold(account.Email, email) {
			return account, nil
		}
	}
	return domain.User{}, domain.ErrUserNotFound
}

func (store *emailChangeUsers) FindByID(_ context.Context, userID int) (domain.User, error) {
	account, exists := store.accounts[userID]
	if !exists {
		return domain.User{}, domain.ErrUserNotFound
	}
	return account, nil
}

func (store *emailChangeUsers) UpdatePassword(_ context.Context, userID int, passwordHash string) error {
	account, exists := store.accounts[userID]
	if !exists {
		return domain.ErrUserNotFound
	}
	account.PasswordHash = passwordHash
	store.accounts[userID] = account
	return nil
}

func (store *emailChangeUsers) MarkVerified(_ context.Context, userID int) error {
	account, exists := store.accounts[userID]
	if !exists {
		return domain.ErrUserNotFound
	}
	account.IsVerified = true
	store.accounts[userID] = account
	return nil
}

func (store *emailChangeUsers) UpdateEmail(
	_ context.Context,
	userID int,
	expectedEmail string,
	newEmail string,
) error {
	account, exists := store.accounts[userID]
	if !exists || account.Email != expectedEmail {
		return domain.ErrEmailChangeStale
	}
	for otherID, other := range store.accounts {
		if otherID != userID && strings.EqualFold(other.Email, newEmail) {
			return domain.ErrEmailTaken
		}
	}
	account.Email = newEmail
	account.IsVerified = true
	store.accounts[userID] = account
	return nil
}

var (
	_ authports.VerifiedUserStore = (*emailChangeUsers)(nil)
	_ authports.EmailChangeStore  = (*emailChangeUsers)(nil)
)

type emailChangeOTPStore struct {
	codes map[string]string
}

func (store *emailChangeOTPStore) Put(_ context.Context, purpose, email, code string, _ time.Duration) error {
	if store.codes == nil {
		store.codes = make(map[string]string)
	}
	store.codes[purpose+":"+email] = code
	return nil
}

func (store *emailChangeOTPStore) Consume(_ context.Context, purpose, email, code string) error {
	key := purpose + ":" + email
	if store.codes[key] != code {
		return domain.ErrInvalidOTP
	}
	delete(store.codes, key)
	return nil
}

var _ authports.OTPStore = (*emailChangeOTPStore)(nil)

type emailChangeSender struct {
	recipient string
	code      string
}

func (sender *emailChangeSender) Send(_ context.Context, recipient, code string) error {
	sender.recipient = recipient
	sender.code = code
	return nil
}

var _ authports.OTPSender = (*emailChangeSender)(nil)

type emailChangeNotifier struct {
	previousEmail string
	newEmail      string
}

func (notifier *emailChangeNotifier) NotifyEmailChanged(_ context.Context, previousEmail, newEmail string) error {
	notifier.previousEmail = previousEmail
	notifier.newEmail = newEmail
	return nil
}

var _ authports.EmailChangeNotifier = (*emailChangeNotifier)(nil)

func newEmailChangeService(t *testing.T) (*verification.OTPService, *emailChangeUsers, *emailChangeSender, *emailChangeNotifier) {
	t.Helper()
	passwordHash, err := authpassword.Hash("current-password")
	if err != nil {
		t.Fatalf("hash current password: %v", err)
	}
	users := &emailChangeUsers{accounts: map[int]domain.User{
		42: {
			ID:           42,
			Email:        "old@example.test",
			Role:         domain.Passenger,
			PasswordHash: passwordHash,
			IsVerified:   true,
		},
	}}
	sender := &emailChangeSender{}
	notifier := &emailChangeNotifier{}
	service := verification.NewOTPService(verification.Dependencies{
		Users:         users,
		EmailChanges:  users,
		EmailNotifier: notifier,
		Store:         &emailChangeOTPStore{},
		Gateway:       sender,
	})
	return service, users, sender, notifier
}

func TestEmailChangeRequiresPasswordAndVerifiesNewAddress(t *testing.T) {
	service, users, sender, notifier := newEmailChangeService(t)
	ctx := context.Background()
	if err := service.RequestEmailChange(ctx, 42, "wrong-password", "new@example.test"); !errors.Is(err, domain.ErrInvalidCredentials) {
		t.Fatalf("RequestEmailChange() error = %v, want invalid credentials", err)
	}
	if sender.recipient != "" {
		t.Fatalf("sent verification code before password reauthentication: %#v", sender)
	}
	if err := service.RequestEmailChange(ctx, 42, "current-password", " New@Example.Test "); err != nil {
		t.Fatalf("RequestEmailChange() error = %v", err)
	}
	if sender.recipient != "new@example.test" || sender.code == "" {
		t.Fatalf("verification delivery = %#v", sender)
	}
	if users.accounts[42].Email != "old@example.test" {
		t.Fatalf("email changed before OTP confirmation: %#v", users.accounts[42])
	}
	if err := service.ConfirmEmailChange(ctx, 42, "new@example.test", sender.code); err != nil {
		t.Fatalf("ConfirmEmailChange() error = %v", err)
	}
	if account := users.accounts[42]; account.Email != "new@example.test" || !account.IsVerified {
		t.Fatalf("confirmed account = %#v", account)
	}
	if notifier.previousEmail != "old@example.test" || notifier.newEmail != "new@example.test" {
		t.Fatalf("email change notification = %#v", notifier)
	}
}

func TestEmailChangeRejectsInvalidOrTakenAddresses(t *testing.T) {
	service, users, sender, _ := newEmailChangeService(t)
	users.accounts[43] = domain.User{ID: 43, Email: "taken@example.test", IsVerified: true}

	for _, test := range []struct {
		name  string
		email string
		want  error
	}{
		{name: "invalid", email: "not an email", want: domain.ErrInvalidEmail},
		{name: "taken", email: "taken@example.test", want: domain.ErrEmailTaken},
		{name: "unchanged", email: "OLD@example.test", want: domain.ErrEmailUnchanged},
	} {
		t.Run(test.name, func(t *testing.T) {
			err := service.RequestEmailChange(context.Background(), 42, "current-password", test.email)
			if !errors.Is(err, test.want) {
				t.Fatalf("RequestEmailChange() error = %v, want %v", err, test.want)
			}
		})
	}
	if sender.recipient != "" {
		t.Fatalf("sent verification code for an invalid request: %#v", sender)
	}
}

func TestEmailChangeConsumesOTPBeforeUpdatingAccount(t *testing.T) {
	service, users, sender, notifier := newEmailChangeService(t)
	ctx := context.Background()
	if err := service.RequestEmailChange(ctx, 42, "current-password", "new@example.test"); err != nil {
		t.Fatalf("RequestEmailChange() error = %v", err)
	}
	if err := service.ConfirmEmailChange(ctx, 42, "new@example.test", sender.code+"x"); !errors.Is(err, domain.ErrInvalidOTP) {
		t.Fatalf("ConfirmEmailChange() error = %v, want invalid OTP", err)
	}
	if users.accounts[42].Email != "old@example.test" || notifier.previousEmail != "" {
		t.Fatalf("invalid OTP changed account or sent notification: account=%#v notifier=%#v", users.accounts[42], notifier)
	}
	firstCode := sender.code
	if err := service.ConfirmEmailChange(ctx, 42, "new@example.test", firstCode); err != nil {
		t.Fatalf("ConfirmEmailChange() after invalid code error = %v", err)
	}
	if err := service.RequestEmailChange(ctx, 42, "current-password", "next@example.test"); err != nil {
		t.Fatalf("RequestEmailChange() after change error = %v", err)
	}
	if err := service.ConfirmEmailChange(ctx, 42, "next@example.test", firstCode); !errors.Is(err, domain.ErrInvalidOTP) {
		t.Fatalf("replayed ConfirmEmailChange() error = %v, want invalid OTP", err)
	}
}

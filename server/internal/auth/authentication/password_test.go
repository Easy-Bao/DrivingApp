package authentication_test

import (
	"testing"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/authentication"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/registration"
	"golang.org/x/crypto/bcrypt"
)

func testHashPassword(password string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.MinCost)
	return string(hash), err
}

func testPasswordHash(t *testing.T, password string) string {
	t.Helper()
	hash, err := testHashPassword(password)
	if err != nil {
		t.Fatalf("hash test password: %v", err)
	}
	return hash
}

func newTestRegisterService(dependencies registration.Dependencies) *registration.RegisterService {
	dependencies.HashPassword = testHashPassword
	return registration.NewRegisterService(dependencies)
}

func newTestAuthenticateService(dependencies authentication.Dependencies) *authentication.AuthenticateService {
	dependencies.HashPassword = testHashPassword
	return authentication.NewAuthenticateService(dependencies)
}

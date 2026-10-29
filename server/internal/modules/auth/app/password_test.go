package app_test

import (
	"testing"

	authapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/app"
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

func newTestRegisterService(dependencies authapp.RegisterDependencies) *authapp.RegisterService {
	dependencies.HashPassword = testHashPassword
	return authapp.NewRegisterService(dependencies)
}

func newTestAuthenticateService(dependencies authapp.AuthenticateDependencies) *authapp.AuthenticateService {
	dependencies.HashPassword = testHashPassword
	minCostHash, _ := testHashPassword("dummy")
	dependencies.DummyHash = minCostHash
	return authapp.NewAuthenticateService(dependencies)
}

package security

import "testing"

func TestAdminAuthorizerUsesConfiguredNumericSubjects(t *testing.T) {
	authorizer := NewAdminAuthorizer(" 7, 42, invalid,  ")
	if !authorizer.IsAdmin("7") || !authorizer.IsAdmin("42") {
		t.Fatal("configured administrator was rejected")
	}
	if authorizer.IsAdmin("8") || authorizer.IsAdmin("invalid") || authorizer.IsAdmin("") {
		t.Fatal("unconfigured subject was accepted as administrator")
	}
}

func TestAdminAuthorizerFailsClosedWhenUnconfigured(t *testing.T) {
	if NewAdminAuthorizer("").IsAdmin("7") {
		t.Fatal("empty administrator configuration must fail closed")
	}
}

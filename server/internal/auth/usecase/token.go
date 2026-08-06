package usecase

import (
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
)

type roleTokenIssuer interface {
	IssueWithRole(subject, role string) (string, error)
}

func issueToken(issuer domain.TokenIssuer, subject string, role domain.Role) (string, error) {
	if roleIssuer, ok := issuer.(roleTokenIssuer); ok {
		return roleIssuer.IssueWithRole(subject, string(role))
	}
	return issuer.Issue(subject)
}

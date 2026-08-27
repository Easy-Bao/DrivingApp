package security

import (
	"strconv"
	"strings"
)

// AdminAuthorizer keeps the privileged user set outside the token format. This
// lets operators revoke administrative access without changing passenger or
// driver role semantics.
type AdminAuthorizer struct {
	allowed map[string]struct{}
}

func NewAdminAuthorizer(rawIDs string) *AdminAuthorizer {
	allowed := make(map[string]struct{})
	for rawID := range strings.SplitSeq(rawIDs, ",") {
		id, err := strconv.Atoi(strings.TrimSpace(rawID))
		if err == nil && id > 0 {
			allowed[strconv.Itoa(id)] = struct{}{}
		}
	}
	return &AdminAuthorizer{allowed: allowed}
}

func (authorizer *AdminAuthorizer) IsAdmin(subject string) bool {
	if authorizer == nil || subject == "" {
		return false
	}
	_, ok := authorizer.allowed[subject]
	return ok
}

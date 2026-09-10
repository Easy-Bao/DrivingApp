package ports

// TokenIssuer keeps token signing behind the auth application boundary.
type TokenIssuer interface {
	Issue(subject string) (string, error)
}

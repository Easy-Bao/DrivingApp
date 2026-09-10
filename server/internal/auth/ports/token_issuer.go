package ports

// TokenIssuer issues signed access and refresh tokens for authenticated users.
type TokenIssuer interface {
	Issue(subject string) (string, error)
}

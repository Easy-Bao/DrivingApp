package database

import "net/url"

// NormalizePostgresURL supplies the local Compose TLS default only when the
// connection URL does not specify its own policy.
func NormalizePostgresURL(databaseURL string) string {
	parsed, err := url.Parse(databaseURL)
	if err != nil {
		return databaseURL
	}
	host := parsed.Hostname()
	isLocalHost := host == "localhost" || host == "127.0.0.1" || host == "postgres-db"
	if !isLocalHost {
		return databaseURL
	}
	query := parsed.Query()
	if query.Has("sslmode") {
		return databaseURL
	}
	query.Set("sslmode", "disable")
	parsed.RawQuery = query.Encode()
	return parsed.String()
}

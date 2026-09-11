package database

import "net/url"

// NormalizePostgresURL makes local Compose connections explicit about TLS.
// Production URLs keep their configured SSL mode unchanged.
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
	query.Set("sslmode", "disable")
	parsed.RawQuery = query.Encode()
	return parsed.String()
}

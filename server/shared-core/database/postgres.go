package database

import (
	"context"
	"database/sql"
	"fmt"
	"net/url"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	_ "github.com/lib/pq"
)

func OpenPostgres(databaseURL string) (*ent.Client, error) {
	if databaseURL == "" {
		return nil, fmt.Errorf("database URL is required")
	}
	databaseURL = NormalizePostgresURL(databaseURL)
	connection, err := sql.Open("postgres", databaseURL)
	if err != nil {
		return nil, err
	}
	if err := connection.PingContext(context.Background()); err != nil {
		_ = connection.Close()
		return nil, err
	}
	_ = connection.Close()
	client, err := ent.Open("postgres", databaseURL)
	if err != nil {
		return nil, err
	}
	return client, nil
}

// NormalizePostgresURL makes local Compose connections explicit about TLS.
// Production URLs keep their configured SSL mode unchanged.
func NormalizePostgresURL(databaseURL string) string {
	parsed, err := url.Parse(databaseURL)
	if err != nil {
		return databaseURL
	}
	host := parsed.Hostname()
	if host != "localhost" && host != "127.0.0.1" && host != "postgres-db" {
		return databaseURL
	}
	query := parsed.Query()
	query.Set("sslmode", "disable")
	parsed.RawQuery = query.Encode()
	return parsed.String()
}

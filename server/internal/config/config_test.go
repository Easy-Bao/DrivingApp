package config

import (
	"errors"
	"log/slog"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/email"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/middleware"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/lifecycle"
)

func TestLoadApplicationUsesDefaults(t *testing.T) {
	config, err := loadApplication(environment(baseEnvironment()))
	if err != nil {
		t.Fatalf("loadApplication() error = %v", err)
	}
	if config.Host != "127.0.0.1" || config.Port != "8000" || config.LogLevel != slog.LevelInfo {
		t.Fatalf("server defaults = host %q, port %q, log level %v", config.Host, config.Port, config.LogLevel)
	}
	if config.PostgresPool != database.DefaultPostgresNativePoolConfig() {
		t.Fatalf("postgres pool defaults = %#v", config.PostgresPool)
	}
	if config.RateLimits != middleware.DefaultRateLimitConfig() {
		t.Fatalf("rate-limit defaults = %#v", config.RateLimits)
	}
	if config.Security.JSONBodyLimit != 16<<10 || config.Security.UploadBodyLimit != 10<<20 {
		t.Fatalf("body limits = %d/%d", config.Security.JSONBodyLimit, config.Security.UploadBodyLimit)
	}
	if config.RideLifecycle != lifecycle.DefaultConfig() {
		t.Fatalf("ride lifecycle defaults = %#v", config.RideLifecycle)
	}
	if config.Bidding.SessionDuration != 5*time.Minute {
		t.Fatalf("bid session duration = %s, want 5m", config.Bidding.SessionDuration)
	}
	if config.Mail.FromName != "DriveApp" || config.Mail.Subject != "DriveApp verification code" ||
		config.Mail.Security != "starttls" || config.Mail.Timeout != 10*time.Second {
		t.Fatalf("mail defaults = sender %q, subject %q, security %q, timeout %s",
			config.Mail.FromName, config.Mail.Subject, config.Mail.Security, config.Mail.Timeout)
	}
	if !errors.Is(config.Mail.Validate(), email.ErrNotConfigured) {
		t.Fatalf("mail config error = %v, want optional mail to remain unconfigured", config.Mail.Validate())
	}
	if config.MinIO.Endpoint != "minio:9000" || config.MinIO.Secure {
		t.Fatalf("MinIO Docker defaults = endpoint %q, secure %t", config.MinIO.Endpoint, config.MinIO.Secure)
	}
}

func TestLoadApplicationReadsOverrides(t *testing.T) {
	values := baseEnvironment()
	for key, value := range map[string]string{
		"API_HOST":                            "0.0.0.0",
		"LOG_LEVEL":                           "warning",
		"CORS_ALLOWED_ORIGINS":                "https://one.example, https://two.example, ",
		"ENABLE_HSTS":                         "true",
		"JSON_BODY_LIMIT_BYTES":               "2048",
		"UPLOAD_BODY_LIMIT_BYTES":             "4096",
		"AUTH_RATE_LIMIT_REQUESTS_PER_MINUTE": "20",
		"POSTGRES_MAX_OPEN_CONNECTIONS":       "40",
		"POSTGRES_MIN_CONNECTIONS":            "4",
		"POSTGRES_MIN_IDLE_CONNECTIONS":       "8",
		"POSTGRES_CONNECTION_MAX_LIFETIME":    "45m",
		"POSTGRES_CONNECTION_MAX_IDLE_TIME":   "8m",
		"POSTGRES_PING_TIMEOUT":               "3s",
		"MAIL_HOST":                           "mail.example.test",
		"MAIL_PORT":                           "465",
		"MAIL_USERNAME":                       "mailer@example.test",
		"MAIL_PASSWORD":                       "test-mail-password",
		"MAIL_FROM":                           "noreply@example.test",
		"MAIL_FROM_NAME":                      "EasyRide",
		"MAIL_SUBJECT":                        "Sign in to EasyRide",
		"MAIL_SECURITY":                       "ssl",
		"MAIL_TIMEOUT":                        "4s",
		"MINIO_USE_SSL":                       "true",
		"PASSENGER_NO_SHOW_WAIT":              "10m",
		"DRIVER_LOCATION_MAX_AGE":             "60s",
		"RIDE_ARRIVAL_RADIUS_METERS":          "180.5",
		"RIDE_COMPLETION_RADIUS_METERS":       "100.25",
		"BID_SESSION_DURATION":                "9m",
		"REPORTING_TIMEZONE":                  "Asia/Manila",
	} {
		values[key] = value
	}

	config, err := loadApplication(environment(values))
	if err != nil {
		t.Fatalf("loadApplication() error = %v", err)
	}
	if config.Host != "0.0.0.0" || config.LogLevel != slog.LevelWarn {
		t.Fatalf("host/log level = %q/%v", config.Host, config.LogLevel)
	}
	if len(config.Security.AllowedOrigins) != 2 || !config.Security.EnableHSTS ||
		config.Security.JSONBodyLimit != 2048 || config.Security.UploadBodyLimit != 4096 {
		t.Fatalf("security configuration = %#v", config.Security)
	}
	if config.RateLimits.Authentication != 20 {
		t.Fatalf("authentication rate limit = %d, want 20", config.RateLimits.Authentication)
	}
	if config.PostgresPool.MaxConnections != 40 || config.PostgresPool.MinConnections != 4 ||
		config.PostgresPool.MinIdleConnections != 8 || config.PostgresPool.ConnectionMaxLifetime != 45*time.Minute ||
		config.PostgresPool.ConnectionMaxIdleTime != 8*time.Minute || config.PostgresPool.PingTimeout != 3*time.Second {
		t.Fatalf("postgres pool overrides = %#v", config.PostgresPool)
	}
	if config.Mail.Port != 465 || config.Mail.Security != "ssl" || config.Mail.Timeout != 4*time.Second {
		t.Fatalf("mail overrides = port %d, security %q, timeout %s", config.Mail.Port, config.Mail.Security, config.Mail.Timeout)
	}
	if !config.MinIO.Secure || config.RideLifecycle.PassengerWaitDuration != 10*time.Minute ||
		config.RideLifecycle.DriverLocationMaxAge != 60*time.Second || config.RideLifecycle.ArrivalRadiusMeters != 180.5 ||
		config.RideLifecycle.CompletionRadiusMeters != 100.25 || config.Bidding.SessionDuration != 9*time.Minute {
		t.Fatalf("MinIO/ride overrides = secure %t, lifecycle %#v, bidding %#v",
			config.MinIO.Secure, config.RideLifecycle, config.Bidding)
	}
}

func TestLoadMigrationUsesPoolDefaults(t *testing.T) {
	config, err := loadMigration(environment(map[string]string{"DATABASE_URL": "postgres://db/driveapp"}))
	if err != nil {
		t.Fatalf("loadMigration() error = %v", err)
	}
	if config.DatabaseURL != "postgres://db/driveapp" ||
		config.PostgresPool != database.DefaultPostgresNativePoolConfig() {
		t.Fatalf("migration config = %#v", config)
	}
}

func TestLoadObjectStorageMigrationUsesDockerMinIOSettings(t *testing.T) {
	config, err := loadObjectStorageMigration(environment(baseEnvironment()))
	if err != nil {
		t.Fatalf("loadObjectStorageMigration() error = %v", err)
	}
	if config.MinIO.Endpoint != "minio:9000" || config.MinIO.Bucket != "private-objects" || config.MinIO.Secure {
		t.Fatalf("object storage migration MinIO config = endpoint %q, bucket %q, secure %t",
			config.MinIO.Endpoint, config.MinIO.Bucket, config.MinIO.Secure)
	}
}

func TestLoadApplicationRejectsInvalidEnvironment(t *testing.T) {
	tests := map[string]func(map[string]string){
		"missing database URL": func(values map[string]string) { delete(values, "DATABASE_URL") },
		"missing Redis URL":    func(values map[string]string) { delete(values, "REDIS_URL") },
		"short JWT secret":     func(values map[string]string) { values["JWT_SECRET"] = "short" },
		"missing API port":     func(values map[string]string) { delete(values, "API_PORT") },
		"invalid API port":     func(values map[string]string) { values["API_PORT"] = "70000" },
		"missing MinIO bucket": func(values map[string]string) { delete(values, "MINIO_BUCKET") },
		"invalid MinIO TLS":    func(values map[string]string) { values["MINIO_USE_SSL"] = "sometimes" },
		"invalid pool size":    func(values map[string]string) { values["POSTGRES_MAX_OPEN_CONNECTIONS"] = "many" },
		"invalid rate limit":   func(values map[string]string) { values["AUTH_RATE_LIMIT_REQUESTS_PER_MINUTE"] = "0" },
		"invalid HSTS setting": func(values map[string]string) { values["ENABLE_HSTS"] = "sometimes" },
		"partial mail settings": func(values map[string]string) {
			values["MAIL_HOST"] = "mail.example.test"
		},
		"invalid mail port": func(values map[string]string) {
			values["MAIL_HOST"] = "mail.example.test"
			values["MAIL_USERNAME"] = "mailer"
			values["MAIL_PASSWORD"] = "test-password"
			values["MAIL_FROM"] = "noreply@example.test"
			values["MAIL_PORT"] = "not-a-port"
		},
		"invalid mail security": func(values map[string]string) {
			values["MAIL_SECURITY"] = "plain"
		},
		"fractional lifecycle duration": func(values map[string]string) {
			values["PASSENGER_NO_SHOW_WAIT"] = "1500ms"
		},
		"oversized lifecycle duration": func(values map[string]string) {
			values["DRIVER_LOCATION_MAX_AGE"] = "2147483648s"
		},
		"negative bid duration": func(values map[string]string) {
			values["BID_SESSION_DURATION"] = "-1m"
		},
		"invalid ride radius": func(values map[string]string) {
			values["RIDE_ARRIVAL_RADIUS_METERS"] = "NaN"
		},
		"invalid reporting timezone": func(values map[string]string) {
			values["REPORTING_TIMEZONE"] = "No/Such_Zone"
		},
	}
	for name, change := range tests {
		t.Run(name, func(t *testing.T) {
			values := cloneEnvironment(baseEnvironment())
			change(values)
			if _, err := loadApplication(environment(values)); err == nil {
				t.Fatal("loadApplication() accepted invalid environment")
			}
		})
	}
}

func baseEnvironment() map[string]string {
	return map[string]string{
		"DATABASE_URL":     "postgres://db:5432/driveapp",
		"REDIS_URL":        "redis://redis:6379",
		"JWT_SECRET":       "a-test-secret-that-is-long-enough-for-hmac-signing",
		"API_PORT":         "8000",
		"MINIO_ENDPOINT":   "minio:9000",
		"MINIO_ACCESS_KEY": "driveapp",
		"MINIO_SECRET_KEY": "test-secret",
		"MINIO_BUCKET":     "private-objects",
	}
}

func environment(values map[string]string) environmentReader {
	return func(key string) string { return values[key] }
}

func cloneEnvironment(values map[string]string) map[string]string {
	clone := make(map[string]string, len(values))
	for key, value := range values {
		clone[key] = value
	}
	return clone
}

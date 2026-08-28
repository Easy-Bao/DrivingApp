package email

import (
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

const (
	securityStartTLS = "starttls"
	securitySSL      = "ssl"
	securityNone     = "none"
)

var (
	ErrNotConfigured = errors.New("mail is not configured")
	ErrInvalidConfig = errors.New("invalid mail configuration")
)

type Config struct {
	Host     string
	Port     int
	Username string
	Password string
	From     string
	FromName string
	Subject  string
	Security string
	Timeout  time.Duration
}

func NewConfigFromEnv() Config {
	return configFromEnv(os.Getenv)
}

func configFromEnv(getenv func(string) string) Config {
	return Config{
		Host:     strings.TrimSpace(getenv("MAIL_HOST")),
		Port:     integerEnv(getenv, "MAIL_PORT", 0),
		Username: strings.TrimSpace(getenv("MAIL_USERNAME")),
		Password: getenv("MAIL_PASSWORD"),
		From:     strings.TrimSpace(getenv("MAIL_FROM")),
		FromName: strings.TrimSpace(defaultEnv(getenv, "MAIL_FROM_NAME", "DriveApp")),
		Subject:  defaultEnv(getenv, "MAIL_SUBJECT", "DriveApp verification code"),
		Security: strings.ToLower(defaultEnv(getenv, "MAIL_SECURITY", securityStartTLS)),
		Timeout:  durationEnv(getenv, "MAIL_TIMEOUT", 10*time.Second),
	}
}

func (config Config) Validate() error {
	missing := make([]string, 0, 5)
	if config.Host == "" {
		missing = append(missing, "MAIL_HOST")
	}
	if config.Username == "" {
		missing = append(missing, "MAIL_USERNAME")
	}
	if config.Password == "" {
		missing = append(missing, "MAIL_PASSWORD")
	}
	if config.From == "" {
		missing = append(missing, "MAIL_FROM")
	}
	if len(missing) > 0 {
		return fmt.Errorf("%w: missing %s", ErrNotConfigured, strings.Join(missing, ", "))
	}
	if config.Port < 1 || config.Port > 65535 {
		return fmt.Errorf("%w: MAIL_PORT must be between 1 and 65535", ErrInvalidConfig)
	}
	if config.Subject == "" {
		return fmt.Errorf("%w: MAIL_SUBJECT must not be empty", ErrInvalidConfig)
	}
	if config.Timeout <= 0 {
		return fmt.Errorf("%w: MAIL_TIMEOUT must be positive", ErrInvalidConfig)
	}
	switch config.Security {
	case securityStartTLS, securitySSL, securityNone:
		return nil
	default:
		return fmt.Errorf("%w: MAIL_SECURITY must be starttls, ssl, or none", ErrInvalidConfig)
	}
}

func integerEnv(getenv func(string) string, key string, fallback int) int {
	raw := strings.TrimSpace(getenv(key))
	if raw == "" {
		return fallback
	}
	value, err := strconv.Atoi(raw)
	if err != nil {
		return 0
	}
	return value
}

func durationEnv(getenv func(string) string, key string, fallback time.Duration) time.Duration {
	raw := strings.TrimSpace(getenv(key))
	if raw == "" {
		return fallback
	}
	value, err := time.ParseDuration(raw)
	if err != nil {
		return 0
	}
	return value
}

func defaultEnv(getenv func(string) string, key, fallback string) string {
	if value := strings.TrimSpace(getenv(key)); value != "" {
		return value
	}
	return fallback
}

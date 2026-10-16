package email

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

const (
	_securityStartTLS = "starttls"
	_securitySSL      = "ssl"
	_securityNone     = "none"
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
	if len(missing) == 4 {
		return fmt.Errorf("%w: missing %s", ErrNotConfigured, strings.Join(missing, ", "))
	}
	if len(missing) > 0 {
		return fmt.Errorf("%w: incomplete settings; missing %s", ErrInvalidConfig, strings.Join(missing, ", "))
	}
	if err := config.ValidateSettings(); err != nil {
		return err
	}
	if config.Port < 1 || config.Port > 65535 {
		return fmt.Errorf("%w: MAIL_PORT must be between 1 and 65535", ErrInvalidConfig)
	}
	return nil
}

func (config Config) ValidateSettings() error {
	if config.Port < 0 || config.Port > 65535 {
		return fmt.Errorf("%w: MAIL_PORT must be between 0 and 65535", ErrInvalidConfig)
	}
	if config.Subject == "" {
		return fmt.Errorf("%w: MAIL_SUBJECT must not be empty", ErrInvalidConfig)
	}
	if config.Timeout <= 0 {
		return fmt.Errorf("%w: MAIL_TIMEOUT must be positive", ErrInvalidConfig)
	}
	switch config.Security {
	case _securityStartTLS, _securitySSL, _securityNone:
		return nil
	default:
		return fmt.Errorf("%w: MAIL_SECURITY must be starttls, ssl, or none", ErrInvalidConfig)
	}
}

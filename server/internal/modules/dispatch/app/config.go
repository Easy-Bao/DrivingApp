package app

import "time"

const DefaultSessionDuration = 90 * time.Second

type Config struct {
	SessionDuration time.Duration
}

func DefaultConfig() Config {
	return Config{SessionDuration: DefaultSessionDuration}
}

func (config Config) sessionDuration() time.Duration {
	if config.SessionDuration <= 0 {
		return DefaultSessionDuration
	}
	return config.SessionDuration
}

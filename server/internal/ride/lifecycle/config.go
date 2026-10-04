package lifecycle

import "time"

const DefaultPassengerWaitDuration = 5 * time.Minute

// Config contains server-authoritative ride lifecycle policy values.
type Config struct {
	PassengerWaitDuration time.Duration
}

func DefaultConfig() Config {
	return Config{PassengerWaitDuration: DefaultPassengerWaitDuration}
}

func (config Config) passengerWaitDuration() time.Duration {
	if config.PassengerWaitDuration <= 0 {
		return DefaultPassengerWaitDuration
	}
	return config.PassengerWaitDuration
}

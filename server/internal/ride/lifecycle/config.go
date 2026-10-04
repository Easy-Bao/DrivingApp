package lifecycle

import "time"

const DefaultPassengerWaitDuration = 5 * time.Minute

const (
	DefaultArrivalRadiusMeters    = 250.0
	DefaultCompletionRadiusMeters = 250.0
)

// Config contains server-authoritative ride lifecycle policy values.
type Config struct {
	PassengerWaitDuration  time.Duration
	ArrivalRadiusMeters    float64
	CompletionRadiusMeters float64
}

func DefaultConfig() Config {
	return Config{
		PassengerWaitDuration:  DefaultPassengerWaitDuration,
		ArrivalRadiusMeters:    DefaultArrivalRadiusMeters,
		CompletionRadiusMeters: DefaultCompletionRadiusMeters,
	}
}

func (config Config) arrivalRadiusMeters() float64 {
	if config.ArrivalRadiusMeters <= 0 {
		return DefaultArrivalRadiusMeters
	}
	return config.ArrivalRadiusMeters
}

func (config Config) completionRadiusMeters() float64 {
	if config.CompletionRadiusMeters <= 0 {
		return DefaultCompletionRadiusMeters
	}
	return config.CompletionRadiusMeters
}

func (config Config) passengerWaitDuration() time.Duration {
	if config.PassengerWaitDuration <= 0 {
		return DefaultPassengerWaitDuration
	}
	return config.PassengerWaitDuration
}

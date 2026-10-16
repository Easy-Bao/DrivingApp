package app

import "time"

const DefaultPassengerWaitDuration = 5 * time.Minute
const DefaultDriverLocationMaxAge = 45 * time.Second

const (
	DefaultArrivalRadiusMeters    = 250.0
	DefaultCompletionRadiusMeters = 250.0
)

// LifecycleConfig contains server-authoritative ride lifecycle policy values.
type LifecycleConfig struct {
	PassengerWaitDuration  time.Duration
	DriverLocationMaxAge   time.Duration
	ArrivalRadiusMeters    float64
	CompletionRadiusMeters float64
}

func DefaultLifecycleConfig() LifecycleConfig {
	return LifecycleConfig{
		PassengerWaitDuration:  DefaultPassengerWaitDuration,
		DriverLocationMaxAge:   DefaultDriverLocationMaxAge,
		ArrivalRadiusMeters:    DefaultArrivalRadiusMeters,
		CompletionRadiusMeters: DefaultCompletionRadiusMeters,
	}
}

func (config LifecycleConfig) driverLocationMaxAge() time.Duration {
	if config.DriverLocationMaxAge <= 0 {
		return DefaultDriverLocationMaxAge
	}
	return config.DriverLocationMaxAge
}

func (config LifecycleConfig) arrivalRadiusMeters() float64 {
	if config.ArrivalRadiusMeters <= 0 {
		return DefaultArrivalRadiusMeters
	}
	return config.ArrivalRadiusMeters
}

func (config LifecycleConfig) completionRadiusMeters() float64 {
	if config.CompletionRadiusMeters <= 0 {
		return DefaultCompletionRadiusMeters
	}
	return config.CompletionRadiusMeters
}

func (config LifecycleConfig) passengerWaitDuration() time.Duration {
	if config.PassengerWaitDuration <= 0 {
		return DefaultPassengerWaitDuration
	}
	return config.PassengerWaitDuration
}

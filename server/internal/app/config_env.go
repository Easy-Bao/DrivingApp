package app

import (
	"errors"
	"fmt"
	"log/slog"
	"math"
	"strconv"
	"strings"
	"time"
)

func requiredValue(getenv environmentReader, key string) (string, error) {
	value := strings.TrimSpace(getenv(key))
	if value == "" {
		return "", fmt.Errorf("%s is required", key)
	}
	return value, nil
}

func requiredDatabaseURL(getenv environmentReader) (string, error) {
	value := strings.TrimSpace(getenv("DATABASE_URL"))
	if value == "" {
		return "", errors.New("database url is required")
	}
	return value, nil
}

func requiredPort(getenv environmentReader, key string) (string, error) {
	value, err := requiredValue(getenv, key)
	if err != nil {
		return "", err
	}
	port, err := strconv.Atoi(value)
	if err != nil || port < 1 || port > 65535 {
		return "", fmt.Errorf("%s must be an integer between 1 and 65535", key)
	}
	return value, nil
}

func valueOrDefault(getenv environmentReader, key, fallback string) string {
	if value := strings.TrimSpace(getenv(key)); value != "" {
		return value
	}
	return fallback
}

func optionalInt(getenv environmentReader, key string, fallback, minimum, maximum int) (int, error) {
	raw := strings.TrimSpace(getenv(key))
	if raw == "" {
		return fallback, nil
	}
	value, err := strconv.ParseInt(raw, 10, 32)
	if err != nil || value < int64(minimum) || value > int64(maximum) {
		return 0, fmt.Errorf("%s must be an integer between %d and %d", key, minimum, maximum)
	}
	return int(value), nil
}

func optionalInt32(getenv environmentReader, key string, fallback int32, minimum int64) (int32, error) {
	raw := strings.TrimSpace(getenv(key))
	if raw == "" {
		return fallback, nil
	}
	value, err := strconv.ParseInt(raw, 10, 32)
	if err != nil || value < minimum {
		return 0, fmt.Errorf("%s must be an integer greater than or equal to %d", key, minimum)
	}
	return int32(value), nil
}

func optionalInt64(getenv environmentReader, key string, fallback, minimum int64) (int64, error) {
	raw := strings.TrimSpace(getenv(key))
	if raw == "" {
		return fallback, nil
	}
	value, err := strconv.ParseInt(raw, 10, 64)
	if err != nil || value < minimum {
		return 0, fmt.Errorf("%s must be an integer greater than or equal to %d", key, minimum)
	}
	return value, nil
}

func optionalDuration(getenv environmentReader, key string, fallback, minimum time.Duration) (time.Duration, error) {
	raw := strings.TrimSpace(getenv(key))
	if raw == "" {
		return fallback, nil
	}
	value, err := time.ParseDuration(raw)
	if err != nil || value < minimum {
		return 0, fmt.Errorf("%s must be a duration of at least %s", key, minimum)
	}
	return value, nil
}

func optionalWholeSecondDuration(getenv environmentReader, key string, fallback time.Duration) (time.Duration, error) {
	raw := strings.TrimSpace(getenv(key))
	if raw == "" {
		return fallback, nil
	}
	value, err := time.ParseDuration(raw)
	seconds := value / time.Second
	if err != nil || value <= 0 || value%time.Second != 0 || seconds > 1<<31-1 {
		return 0, fmt.Errorf("%s must be a positive whole-second duration", key)
	}
	return value, nil
}

func optionalPositiveFloat(getenv environmentReader, key string, fallback float64) (float64, error) {
	raw := strings.TrimSpace(getenv(key))
	if raw == "" {
		return fallback, nil
	}
	value, err := strconv.ParseFloat(raw, 64)
	if err != nil || value <= 0 || math.IsNaN(value) || math.IsInf(value, 0) {
		return 0, fmt.Errorf("%s must be a finite positive number", key)
	}
	return value, nil
}

func optionalBool(getenv environmentReader, key string, fallback bool) (bool, error) {
	raw := strings.TrimSpace(getenv(key))
	if raw == "" {
		return fallback, nil
	}
	value, err := strconv.ParseBool(raw)
	if err != nil {
		return false, fmt.Errorf("%s must be a boolean", key)
	}
	return value, nil
}

func parseOrigins(raw string) []string {
	values := strings.Split(raw, ",")
	origins := make([]string, 0, len(values))
	for _, value := range values {
		if origin := strings.TrimSpace(value); origin != "" {
			origins = append(origins, origin)
		}
	}
	return origins
}

func logLevel(raw string) slog.Level {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "debug":
		return slog.LevelDebug
	case "warn", "warning":
		return slog.LevelWarn
	case "error":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}

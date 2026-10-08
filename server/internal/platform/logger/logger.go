package logger

import (
	"log/slog"
	"os"
	"strings"
)

func New(serviceName string) *slog.Logger {
	options := &slog.HandlerOptions{Level: levelFromEnvironment()}
	handler := slog.NewJSONHandler(os.Stdout, options)
	return slog.New(handler).With("service", serviceName)
}

func levelFromEnvironment() slog.Level {
	switch strings.ToLower(strings.TrimSpace(os.Getenv("LOG_LEVEL"))) {
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

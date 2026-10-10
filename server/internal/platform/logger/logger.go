package logger

import (
	"log/slog"
	"os"
)

func New(serviceName string, level slog.Level) *slog.Logger {
	options := &slog.HandlerOptions{Level: level}
	handler := slog.NewJSONHandler(os.Stdout, options)
	return slog.New(handler).With("service", serviceName)
}

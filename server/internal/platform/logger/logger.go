package logger

import (
	"log/slog"
	"os"
)

func New(serviceName string) *slog.Logger {
	options := &slog.HandlerOptions{Level: slog.LevelInfo}
	handler := slog.NewJSONHandler(os.Stdout, options)
	return slog.New(handler).With("service", serviceName)
}

package logger

import (
	"context"
	"log/slog"
	"testing"
)

func TestNewConfiguresMinimumLevel(t *testing.T) {
	tests := []struct {
		name          string
		level         slog.Level
		enabledLevel  slog.Level
		disabledLevel slog.Level
	}{
		{name: "info", level: slog.LevelInfo, enabledLevel: slog.LevelInfo, disabledLevel: slog.LevelDebug},
		{name: "debug", level: slog.LevelDebug, enabledLevel: slog.LevelDebug, disabledLevel: slog.Level(-8)},
		{name: "warn", level: slog.LevelWarn, enabledLevel: slog.LevelWarn, disabledLevel: slog.LevelInfo},
		{name: "error", level: slog.LevelError, enabledLevel: slog.LevelError, disabledLevel: slog.LevelWarn},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			logger := New("logger-test", test.level)
			if !logger.Enabled(context.Background(), test.enabledLevel) {
				t.Errorf("logger.Enabled(%s) = false, want true", test.enabledLevel)
			}
			if logger.Enabled(context.Background(), test.disabledLevel) {
				t.Errorf("logger.Enabled(%s) = true, want false", test.disabledLevel)
			}
		})
	}
}

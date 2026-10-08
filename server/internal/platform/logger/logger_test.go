package logger

import (
	"log/slog"
	"testing"
)

func TestLevelFromEnvironment(t *testing.T) {
	tests := []struct {
		name  string
		value string
		want  slog.Level
	}{
		{name: "default", want: slog.LevelInfo},
		{name: "debug", value: "debug", want: slog.LevelDebug},
		{name: "warning alias", value: "warning", want: slog.LevelWarn},
		{name: "error", value: "error", want: slog.LevelError},
		{name: "invalid defaults to info", value: "verbose", want: slog.LevelInfo},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Setenv("LOG_LEVEL", test.value)
			if got := levelFromEnvironment(); got != test.want {
				t.Fatalf("levelFromEnvironment() = %s, want %s", got, test.want)
			}
		})
	}
}

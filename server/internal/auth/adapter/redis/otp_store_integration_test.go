//go:build integration

package redis

import (
	"context"
	"errors"
	"fmt"
	"net"
	"os"
	"strings"
	"testing"
	"time"

	authdomain "github.com/Easy-Bao/DrivingApp/server/internal/auth/domain"
	redisclient "github.com/redis/go-redis/v9"
)

func TestOTPStoreInvalidatesCodeAfterMaximumAttempts(t *testing.T) {
	redisURL := strings.TrimSpace(os.Getenv("REDIS_URL"))
	if redisURL == "" {
		t.Skip("REDIS_URL is not set")
	}

	options, err := redisclient.ParseURL(redisURL)
	if err != nil {
		t.Fatalf("parse Redis URL: %v", err)
	}
	host, _, err := net.SplitHostPort(options.Addr)
	if err != nil || (host != "localhost" && !net.ParseIP(host).IsLoopback()) {
		t.Skip("OTP store integration test requires a loopback Redis URL")
	}

	client := redisclient.NewClient(options)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := client.Ping(ctx).Err(); err != nil {
		_ = client.Close()
		t.Fatalf("ping local Redis: %v", err)
	}
	defer client.Close()

	email := fmt.Sprintf("otp-lockout-%d@example.test", time.Now().UnixNano())
	otpKey := key("reset", email)
	attemptsKey := attemptKey("reset", email)
	t.Cleanup(func() {
		cleanupCtx, cleanupCancel := context.WithTimeout(context.Background(), time.Second)
		defer cleanupCancel()
		_ = client.Del(cleanupCtx, otpKey, attemptsKey).Err()
	})

	store := NewOTPStore(client)
	if err := store.Put(ctx, "reset", email, "123456", time.Minute); err != nil {
		t.Fatalf("store reset code: %v", err)
	}
	for attempt := int64(1); attempt <= authdomain.MaxOTPVerificationAttempts; attempt++ {
		err := store.Consume(ctx, "reset", email, "000000")
		if attempt < authdomain.MaxOTPVerificationAttempts {
			if !errors.Is(err, authdomain.ErrInvalidOTP) {
				t.Fatalf("attempt %d error = %v, want invalid OTP", attempt, err)
			}
			continue
		}
		if !errors.Is(err, authdomain.ErrOTPMaxAttemptsExceeded) {
			t.Fatalf("attempt %d error = %v, want maximum attempts exceeded", attempt, err)
		}
	}
	if err := store.Consume(ctx, "reset", email, "123456"); !errors.Is(err, authdomain.ErrInvalidOTP) {
		t.Fatalf("consume exhausted code error = %v, want invalid OTP", err)
	}

	if err := store.Put(ctx, "reset", email, "111111", time.Minute); err != nil {
		t.Fatalf("store first replacement reset code: %v", err)
	}
	if err := store.Consume(ctx, "reset", email, "000000"); !errors.Is(err, authdomain.ErrInvalidOTP) {
		t.Fatalf("first replacement code attempt error = %v, want invalid OTP", err)
	}
	if err := store.Put(ctx, "reset", email, "654321", time.Minute); err != nil {
		t.Fatalf("store replacement reset code: %v", err)
	}
	for attempt := int64(1); attempt < authdomain.MaxOTPVerificationAttempts; attempt++ {
		if err := store.Consume(ctx, "reset", email, "000000"); !errors.Is(err, authdomain.ErrInvalidOTP) {
			t.Fatalf("replacement code attempt %d error = %v, want invalid OTP", attempt, err)
		}
	}
	if err := store.Consume(ctx, "reset", email, "654321"); err != nil {
		t.Fatalf("consume replacement code after fewer than maximum invalid attempts: %v", err)
	}
}

package email_test

import (
	"context"
	"errors"
	"net/textproto"
	"testing"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/auth/adapter/email"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/resilience"
	mail "github.com/wneessen/go-mail"
)

func TestMailConfigRequiresCredentials(t *testing.T) {
	err := (email.Config{}).Validate()
	if !errors.Is(err, email.ErrNotConfigured) {
		t.Fatalf("expected ErrNotConfigured, got %v", err)
	}
}

func TestMailConfigRejectsPartialSettings(t *testing.T) {
	err := (email.Config{Host: "mail.example.test"}).Validate()
	if !errors.Is(err, email.ErrInvalidConfig) {
		t.Fatalf("expected ErrInvalidConfig, got %v", err)
	}
}

func TestMailGatewayBuildsVerificationDelivery(t *testing.T) {
	config := validMailConfig()
	var gotRecipient, gotSubject, gotBody string
	gateway := email.NewMailGateway(
		config,
		email.WithDelivery(func(
			_ context.Context,
			_ email.Config,
			recipient string,
			subject string,
			body string,
		) error {
			gotRecipient, gotSubject, gotBody = recipient, subject, body
			return nil
		}),
	)

	if err := gateway.Send(context.Background(), " passenger@example.test ", "123456"); err != nil {
		t.Fatalf("send returned error: %v", err)
	}
	if gotRecipient != "passenger@example.test" || gotSubject != config.Subject {
		t.Fatalf("delivery headers = %q, %q", gotRecipient, gotSubject)
	}
	if gotBody != "Your DriveApp verification code is 123456. It expires in 10 minutes.\n" {
		t.Errorf("body = %q", gotBody)
	}
}

func TestMailGatewayHonorsCanceledContext(t *testing.T) {
	called := false
	gateway := email.NewMailGateway(
		validMailConfig(),
		email.WithDelivery(func(
			context.Context,
			email.Config,
			string,
			string,
			string,
		) error {
			called = true
			return nil
		}),
	)
	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	err := gateway.Send(ctx, "passenger@example.test", "123456")
	if !errors.Is(err, context.Canceled) {
		t.Fatalf("expected context cancellation, got %v", err)
	}
	if called {
		t.Fatal("delivery should not run for a canceled context")
	}
}

func TestMailGatewayRejectsEmptyRecipient(t *testing.T) {
	gateway := email.NewMailGateway(
		validMailConfig(),
		email.WithDelivery(func(
			context.Context,
			email.Config,
			string,
			string,
			string,
		) error {
			t.Fatal("delivery should not run for an empty recipient")
			return nil
		}),
	)
	if err := gateway.Send(context.Background(), " ", "123456"); !errors.Is(err, email.ErrInvalidConfig) {
		t.Fatalf("expected ErrInvalidConfig, got %v", err)
	}
}

func TestMailGatewayOpensCircuitAfterDeliveryFailures(t *testing.T) {
	calls := 0
	gateway := email.NewMailGateway(
		validMailConfig(),
		email.WithDelivery(func(
			context.Context,
			email.Config,
			string,
			string,
			string,
		) error {
			calls++
			return errors.New("mail provider unavailable")
		}),
	)
	for range 3 {
		if err := gateway.Send(context.Background(), "passenger@example.test", "123456"); err == nil {
			t.Fatal("expected delivery failure")
		}
	}
	err := gateway.Send(
		context.Background(),
		"passenger@example.test",
		"123456",
	)
	if !errors.Is(err, resilience.ErrCircuitOpen) {
		t.Fatalf("fourth send error = %v, want circuit open", err)
	}
	if calls != 3 {
		t.Fatalf("delivery calls = %d, want 3", calls)
	}
}

func TestMailGatewayDoesNotOpenCircuitOnPermanentRecipientErrors(t *testing.T) {
	calls := 0
	gateway := email.NewMailGateway(
		validMailConfig(),
		email.WithDelivery(func(
			_ context.Context,
			_ email.Config,
			recipient string,
			_ string,
			_ string,
		) error {
			calls++
			switch recipient {
			case "bad-proto@example.test":
				return &textproto.Error{Code: 550, Msg: "5.1.1 user unknown"}
			case "bad-rcpt@example.test":
				return &mail.SendError{Reason: mail.ErrSMTPRcptTo}
			default:
				return nil
			}
		}),
	)

	for range 3 {
		err := gateway.Send(context.Background(), "bad-proto@example.test", "123456")
		if err == nil || errors.Is(err, resilience.ErrCircuitOpen) {
			t.Fatalf("550 recipient error = %v, want non-circuit error", err)
		}
	}
	for range 2 {
		err := gateway.Send(context.Background(), "bad-rcpt@example.test", "123456")
		if err == nil || errors.Is(err, resilience.ErrCircuitOpen) {
			t.Fatalf("RCPT TO error = %v, want non-circuit error", err)
		}
	}
	if err := gateway.Send(context.Background(), "valid@example.test", "123456"); err != nil {
		t.Fatalf("valid recipient after permanent recipient rejections failed: %v", err)
	}
	if calls != 6 {
		t.Fatalf("delivery calls = %d, want 6", calls)
	}
}

func validMailConfig() email.Config {
	return email.Config{
		Host: "mail.example.test", Port: 587, Username: "mailer", Password: "secret",
		From: "noreply@example.test", FromName: "DriveApp", Subject: "Verification code",
		Security: "starttls", Timeout: 10 * time.Second,
	}
}

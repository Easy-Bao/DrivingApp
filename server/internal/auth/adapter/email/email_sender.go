package email

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	authports "github.com/Easy-Bao/DrivingApp/server/internal/auth/ports"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/resilience"
	mail "github.com/wneessen/go-mail"
)

type Delivery func(
	context.Context,
	Config,
	string,
	string,
	string,
) error

type GoMailGatewayOption func(*GoMailGateway)

type GoMailGateway struct {
	config  Config
	deliver Delivery
	breaker *resilience.CircuitBreaker
}

var _ authports.OTPSender = (*GoMailGateway)(nil)

func NewGoMailGateway(config Config, options ...GoMailGatewayOption) *GoMailGateway {
	gateway := newGoMailGateway(config)
	for _, option := range options {
		if option != nil {
			option(gateway)
		}
	}
	return gateway
}

func WithDelivery(deliver Delivery) GoMailGatewayOption {
	return func(gateway *GoMailGateway) {
		if deliver != nil {
			gateway.deliver = deliver
		}
	}
}

func newGoMailGateway(config Config) *GoMailGateway {
	return &GoMailGateway{
		config:  config,
		deliver: deliverWithGoMail,
		breaker: resilience.NewCircuitBreaker(resilience.CircuitBreakerConfig{
			FailureThreshold: 3,
			ResetAfter:       30 * time.Second,
		}),
	}
}

func (gateway *GoMailGateway) Send(ctx context.Context, recipient, code string) error {
	if gateway == nil || gateway.deliver == nil || gateway.breaker == nil {
		return fmt.Errorf("%w: mail gateway is not configured", ErrInvalidConfig)
	}
	if err := gateway.config.Validate(); err != nil {
		return fmt.Errorf("validate mail gateway configuration: %w", err)
	}
	if ctx == nil {
		return errors.New("mail delivery context is nil")
	}
	if err := ctx.Err(); err != nil {
		return err
	}
	recipient = strings.TrimSpace(recipient)
	if recipient == "" {
		return fmt.Errorf("%w: recipient is empty", ErrInvalidConfig)
	}
	if err := gateway.breaker.Do(ctx, func(ctx context.Context) error {
		return gateway.deliver(
			ctx,
			gateway.config,
			recipient,
			gateway.config.Subject,
			verificationBody(code),
		)
	}); err != nil {
		return fmt.Errorf("send verification email: %w", err)
	}
	return nil
}

func deliverWithGoMail(
	ctx context.Context,
	config Config,
	recipient string,
	subject string,
	body string,
) error {
	client, err := mail.NewClient(config.Host, clientOptions(config)...)
	if err != nil {
		return fmt.Errorf("create mail client: %w", err)
	}

	message := mail.NewMsg()
	if config.FromName == "" {
		err = message.From(config.From)
	} else {
		err = message.FromFormat(config.FromName, config.From)
	}
	if err != nil {
		return fmt.Errorf("set mail sender: %w", err)
	}
	if err := message.To(recipient); err != nil {
		return fmt.Errorf("set mail recipient: %w", err)
	}
	message.Subject(subject)
	message.SetBodyString(mail.TypeTextPlain, body)

	if err := client.DialAndSendWithContext(ctx, message); err != nil {
		return fmt.Errorf("deliver mail: %w", err)
	}
	return nil
}

func clientOptions(config Config) []mail.Option {
	options := []mail.Option{
		mail.WithPort(config.Port),
		mail.WithTimeout(config.Timeout),
		mail.WithSMTPAuth(mail.SMTPAuthPlain),
		mail.WithUsername(config.Username),
		mail.WithPassword(config.Password),
	}
	switch config.Security {
	case _securitySSL:
		options = append(options, mail.WithSSL())
	case _securityNone:
		options = append(options, mail.WithTLSPolicy(mail.NoTLS))
	default:
		options = append(options, mail.WithTLSPortPolicy(mail.TLSMandatory))
	}
	return options
}

package email

import (
	"context"
	"fmt"
	"strings"

	mail "github.com/wneessen/go-mail"
)

type Delivery func(context.Context, Config, string, string, string) error

type GoMailGateway struct {
	config  Config
	deliver Delivery
}

func NewGoMailGatewayFromEnv() *GoMailGateway {
	return NewGoMailGateway(NewConfigFromEnv())
}

func NewGoMailGateway(config Config) *GoMailGateway {
	return &GoMailGateway{config: config, deliver: deliverWithGoMail}
}

func NewGoMailGatewayWithDelivery(config Config, deliver Delivery) *GoMailGateway {
	if deliver == nil {
		return NewGoMailGateway(config)
	}
	return &GoMailGateway{config: config, deliver: deliver}
}

func (gateway *GoMailGateway) Send(ctx context.Context, recipient, code string) error {
	if err := gateway.config.Validate(); err != nil {
		return err
	}
	if err := ctx.Err(); err != nil {
		return err
	}
	recipient = strings.TrimSpace(recipient)
	if recipient == "" {
		return fmt.Errorf("%w: recipient is empty", ErrInvalidConfig)
	}
	return gateway.deliver(ctx, gateway.config, recipient, gateway.config.Subject, verificationBody(code))
}

func deliverWithGoMail(ctx context.Context, config Config, recipient, subject, body string) error {
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
	case securitySSL:
		options = append(options, mail.WithSSL())
	case securityNone:
		options = append(options, mail.WithTLSPolicy(mail.NoTLS))
	default:
		options = append(options, mail.WithTLSPortPolicy(mail.TLSMandatory))
	}
	return options
}

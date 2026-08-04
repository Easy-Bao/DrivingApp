package email

import (
	"context"
	"errors"
	"fmt"
	"net/smtp"
	"os"
	"strconv"
)

var ErrNotConfigured = errors.New("smtp is not configured")

type SMTPGateway struct {
	host string
	port string
	user string
	pass string
	from string
}

func NewSMTPGatewayFromEnv() *SMTPGateway {
	port := os.Getenv("SMTP_PORT")
	if port == "" {
		port = "587"
	}
	return &SMTPGateway{
		host: os.Getenv("SMTP_HOST"),
		port: port,
		user: os.Getenv("SMTP_USER"),
		pass: os.Getenv("SMTP_PASS"),
		from: os.Getenv("SMTP_FROM"),
	}
}

func (gateway *SMTPGateway) Send(ctx context.Context, recipient, code string) error {
	if gateway.host == "" || gateway.user == "" || gateway.pass == "" || gateway.from == "" {
		return ErrNotConfigured
	}
	if _, err := strconv.Atoi(gateway.port); err != nil {
		return fmt.Errorf("invalid smtp port: %w", err)
	}
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
	}
	message := "To: " + recipient + "\r\n" +
		"Subject: DriveApp verification code\r\n" +
		"Content-Type: text/plain; charset=UTF-8\r\n\r\n" +
		"Your DriveApp code is " + code + ". It expires in 10 minutes.\r\n"
	auth := smtp.PlainAuth("", gateway.user, gateway.pass, gateway.host)
	return smtp.SendMail(gateway.host+":"+gateway.port, auth, gateway.from, []string{recipient}, []byte(message))
}

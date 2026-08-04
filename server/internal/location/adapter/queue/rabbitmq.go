package queue

import (
	"context"
	"encoding/json"

	"github.com/Easy-Bao/DrivingApp/server/internal/location/domain"
	"github.com/rabbitmq/amqp091-go"
)

type Publisher struct {
	connection *amqp091.Connection
	channel    *amqp091.Channel
}

func NewPublisher(url string) (*Publisher, error) {
	connection, err := amqp091.Dial(url)
	if err != nil {
		return nil, err
	}
	channel, err := connection.Channel()
	if err != nil {
		_ = connection.Close()
		return nil, err
	}
	if err := channel.ExchangeDeclare("location_events", "topic", true, false, false, false, nil); err != nil {
		_ = channel.Close()
		_ = connection.Close()
		return nil, err
	}
	return &Publisher{connection: connection, channel: channel}, nil
}

func (publisher *Publisher) Publish(ctx context.Context, event domain.LocationEvent) error {
	payload, err := json.Marshal(event)
	if err != nil {
		return err
	}
	return publisher.channel.PublishWithContext(ctx, "location_events", "location.resolved", false, false, amqp091.Publishing{
		ContentType: "application/json",
		Body:        payload,
	})
}

func (publisher *Publisher) Close() error {
	_ = publisher.channel.Close()
	return publisher.connection.Close()
}

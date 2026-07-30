package queue

import (
	"context"
	"encoding/json"
	"location-service/internal/domain"
	"log"

	amqp "github.com/rabbitmq/amqp091-go"
)

type rabbitMQAdapter struct {
	conn *amqp.Connection
	ch   *amqp.Channel
}

func NewRabbitMQAdapter(amqpURL string) domain.QueuePublisher {
	if amqpURL == "" {
		return nil
	}
	conn, err := amqp.Dial(amqpURL)
	if err != nil {
		log.Printf("RabbitMQ connection skipped: %v", err)
		return nil
	}
	ch, err := conn.Channel()
	if err != nil {
		_ = conn.Close()
		log.Printf("RabbitMQ channel error: %v", err)
		return nil
	}

	_ = ch.ExchangeDeclare("location_events", "topic", true, false, false, false, nil)

	return &rabbitMQAdapter{
		conn: conn,
		ch:   ch,
	}
}

func (q *rabbitMQAdapter) PublishLocationEvent(ctx context.Context, event *domain.LocationUpdateEvent) error {
	if q.ch == nil {
		return nil
	}
	body, err := json.Marshal(event)
	if err != nil {
		return err
	}

	return q.ch.PublishWithContext(
		ctx,
		"location_events",
		"location.updated",
		false,
		false,
		amqp.Publishing{
			ContentType: "application/json",
			Body:        body,
		},
	)
}

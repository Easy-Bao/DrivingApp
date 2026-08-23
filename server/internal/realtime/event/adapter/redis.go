package adapter

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/assignment"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/event"
	redis "github.com/redis/go-redis/v9"
)

const Channel = "driveapp.realtime.v1"

const reconnectDelay = time.Second

const (
	rideAssignmentTTL         = 4 * time.Hour
	rideAssignmentKeyPrefix   = "realtime:ride:"
	driverAssignmentsPrefix   = "realtime:driver-rides:"
	passengerAssignmentPrefix = "realtime:passenger:"
)

type Sink interface {
	Publish(event.Envelope)
}

type RedisPublisher struct {
	client *redis.Client
}

func NewRedisPublisher(client *redis.Client) *RedisPublisher {
	return &RedisPublisher{client: client}
}

func (publisher *RedisPublisher) Publish(ctx context.Context, envelope event.Envelope) error {
	encoded, err := envelope.Encode()
	if err != nil {
		return err
	}
	if err := publisher.client.Publish(ctx, Channel, encoded).Err(); err != nil {
		return fmt.Errorf("publish realtime event: %w", err)
	}
	if err := publisher.syncAssignment(ctx, envelope); err != nil {
		return fmt.Errorf("sync realtime ride assignment: %w", err)
	}
	return nil
}

// RedisRideAssignmentLookup reads the short-lived routing cache established
// by ride match events. It never substitutes for an authoritative ride read.
type RedisRideAssignmentLookup struct {
	client *redis.Client
}

func NewRedisRideAssignmentLookup(client *redis.Client) *RedisRideAssignmentLookup {
	return &RedisRideAssignmentLookup{client: client}
}

func (lookup *RedisRideAssignmentLookup) ForDriver(ctx context.Context, driverID string) ([]assignment.Assignment, error) {
	rideIDs, err := lookup.client.SMembers(ctx, driverAssignmentsKey(driverID)).Result()
	if errors.Is(err, redis.Nil) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("load driver ride assignments: %w", err)
	}
	if len(rideIDs) == 0 {
		return nil, nil
	}

	commands := make([]*redis.MapStringStringCmd, 0, len(rideIDs))
	_, err = lookup.client.Pipelined(ctx, func(pipe redis.Pipeliner) error {
		for _, rideID := range rideIDs {
			commands = append(commands, pipe.HGetAll(ctx, rideAssignmentKey(rideID)))
		}
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("load driver ride assignment details: %w", err)
	}
	result := make([]assignment.Assignment, 0, len(rideIDs))
	for index, command := range commands {
		if value, ok := assignmentFromValues(rideIDs[index], command.Val()); ok {
			result = append(result, value)
		}
	}
	return result, nil
}

func (lookup *RedisRideAssignmentLookup) ForRide(ctx context.Context, rideID string) (assignment.Assignment, bool, error) {
	values, err := lookup.client.HGetAll(ctx, rideAssignmentKey(rideID)).Result()
	if err != nil {
		return assignment.Assignment{}, false, fmt.Errorf("load ride assignment: %w", err)
	}
	value, found := assignmentFromValues(rideID, values)
	return value, found, nil
}

func assignmentFromValues(rideID string, values map[string]string) (assignment.Assignment, bool) {
	value := assignment.Assignment{
		RideID:      rideID,
		DriverID:    values["driver_id"],
		PassengerID: values["passenger_id"],
		Status:      values["status"],
	}
	if value.DriverID == "" || value.PassengerID == "" {
		return assignment.Assignment{}, false
	}
	if value.Status == "" {
		value.Status = "assigned"
	}
	return value, true
}

func (publisher *RedisPublisher) syncAssignment(ctx context.Context, envelope event.Envelope) error {
	switch envelope.Type {
	case event.RideMatched:
		return publisher.activateAssignment(ctx, envelope.Scope)
	case event.RideStatusChanged:
		if isTerminalRideEvent(envelope.Payload) {
			return publisher.deactivateAssignment(ctx, envelope.Scope)
		}
	}
	return nil
}

func (publisher *RedisPublisher) activateAssignment(ctx context.Context, scope event.Scope) error {
	if scope.RideID == "" || scope.DriverID == "" || scope.PassengerID == "" {
		return nil
	}
	_, err := publisher.client.TxPipelined(ctx, func(pipe redis.Pipeliner) error {
		pipe.HSet(ctx, rideAssignmentKey(scope.RideID), map[string]any{
			"driver_id":    scope.DriverID,
			"passenger_id": scope.PassengerID,
			"status":       "assigned",
		})
		pipe.Expire(ctx, rideAssignmentKey(scope.RideID), rideAssignmentTTL)
		pipe.SAdd(ctx, driverAssignmentsKey(scope.DriverID), scope.RideID)
		pipe.Expire(ctx, driverAssignmentsKey(scope.DriverID), rideAssignmentTTL)
		pipe.Set(ctx, passengerAssignmentKey(scope.PassengerID), scope.RideID, rideAssignmentTTL)
		return nil
	})
	return err
}

func (publisher *RedisPublisher) deactivateAssignment(ctx context.Context, scope event.Scope) error {
	if scope.RideID == "" {
		return nil
	}
	if err := publisher.client.Del(ctx, rideAssignmentKey(scope.RideID)).Err(); err != nil {
		return err
	}
	if key := driverAssignmentsKey(scope.DriverID); key != "" {
		if err := publisher.client.SRem(ctx, key, scope.RideID).Err(); err != nil {
			return err
		}
	}
	if err := deleteIfMatches(ctx, publisher.client, passengerAssignmentKey(scope.PassengerID), scope.RideID); err != nil {
		return err
	}
	return nil
}

func isTerminalRideEvent(payload []byte) bool {
	var value struct {
		Ride struct {
			Status string `json:"status"`
		} `json:"ride"`
	}
	if json.Unmarshal(payload, &value) != nil {
		return false
	}
	switch strings.ToLower(value.Ride.Status) {
	case "completed", "canceled", "cancelled":
		return true
	default:
		return false
	}
}

func deleteIfMatches(ctx context.Context, client *redis.Client, key, expectedValue string) error {
	if key == "" {
		return nil
	}
	const script = `if redis.call("GET", KEYS[1]) == ARGV[1] then return redis.call("DEL", KEYS[1]) end return 0`
	return client.Eval(ctx, script, []string{key}, expectedValue).Err()
}

func rideAssignmentKey(rideID string) string {
	return rideAssignmentKeyPrefix + rideID
}

func driverAssignmentsKey(driverID string) string {
	if driverID == "" {
		return ""
	}
	return driverAssignmentsPrefix + driverID
}

func passengerAssignmentKey(passengerID string) string {
	if passengerID == "" {
		return ""
	}
	return passengerAssignmentPrefix + passengerID
}

type RedisSubscriber struct {
	client *redis.Client
}

func NewRedisSubscriber(client *redis.Client) *RedisSubscriber {
	return &RedisSubscriber{client: client}
}

// Run reconnects after transient Redis failures. Invalid messages are dropped:
// Redis Pub/Sub is not an authority boundary and clients recover from REST
// snapshots after reconnecting.
func (subscriber *RedisSubscriber) Run(ctx context.Context, sink Sink) error {
	for {
		if ctx.Err() != nil {
			return nil
		}
		if err := subscriber.forward(ctx, sink); err != nil && ctx.Err() == nil {
			select {
			case <-ctx.Done():
				return nil
			case <-time.After(reconnectDelay):
			}
		}
	}
}

func (subscriber *RedisSubscriber) forward(ctx context.Context, sink Sink) error {
	pubsub := subscriber.client.Subscribe(ctx, Channel)
	defer pubsub.Close()

	if _, err := pubsub.Receive(ctx); err != nil {
		if errors.Is(err, context.Canceled) {
			return nil
		}
		return fmt.Errorf("subscribe to realtime events: %w", err)
	}

	messages := pubsub.Channel()
	for {
		select {
		case <-ctx.Done():
			return nil
		case message, ok := <-messages:
			if !ok {
				return errors.New("realtime event subscription closed")
			}
			envelope, err := event.Decode([]byte(message.Payload))
			if err != nil {
				continue
			}
			sink.Publish(envelope)
		}
	}
}

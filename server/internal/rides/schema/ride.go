package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/dialect/entsql"
	"entgo.io/ent/schema/field"
)

type Ride struct {
	ent.Schema
}

func (Ride) Fields() []ent.Field {
	return []ent.Field{
		field.Int("passenger_id").Positive(),
		field.Int("driver_id").Optional(),
		field.String("status").Default("requested"),
		field.Int64("fare_centavos").NonNegative(),
		field.String("ride_type").Default("Solo Ride"),
		field.Float("pickup_latitude").Optional(),
		field.Float("pickup_longitude").Optional(),
		field.String("pickup_name").Optional(),
		field.Float("dropoff_latitude").Optional(),
		field.Float("dropoff_longitude").Optional(),
		field.String("dropoff_name").Optional(),
		field.Float("distance_km").Optional(),
		field.Float("duration_minutes").Optional(),
		field.String("driver_name").Optional(),
		field.String("vehicle_type").Optional(),
		field.String("plate_number").Optional(),
		field.Float("driver_rating").Optional(),
		field.Time("created_at").
			Default(time.Now).
			Annotations(entsql.DefaultExpr("CURRENT_TIMESTAMP")),
		field.Time("completed_at").Optional(),
		field.String("payment_status").Default("unpaid"),
		field.Time("cash_received_at").Optional(),
		field.Int64("commission_centavos").NonNegative().Default(0),
		field.Int64("driver_payout_centavos").NonNegative().Default(0),
	}
}

type BidSession struct {
	ent.Schema
}

func (BidSession) Fields() []ent.Field {
	return []ent.Field{
		field.Int("passenger_id").Positive(),
		field.String("ride_type").Default("Solo Ride"),
		field.Float("pickup_latitude"),
		field.Float("pickup_longitude"),
		field.String("pickup_name"),
		field.Float("dropoff_latitude"),
		field.Float("dropoff_longitude"),
		field.String("dropoff_name"),
		field.String("passenger_note").Optional().MaxLen(160),
		field.Float("distance_km"),
		field.Float("duration_minutes"),
		field.Int64("offered_fare_centavos").NonNegative(),
		field.String("status").Default("open"),
		field.Int("target_driver_id").Optional(),
		field.Int("accepted_driver_id").Optional(),
		field.Time("expires_at"),
		field.Time("created_at").Default(time.Now),
	}
}

type BidOffer struct {
	ent.Schema
}

func (BidOffer) Fields() []ent.Field {
	return []ent.Field{
		field.Int("session_id").Positive(),
		field.Int("driver_id").Positive(),
		field.String("driver_name").Optional(),
		field.String("plate_number").Optional(),
		field.String("vehicle_type").Optional(),
		field.Int64("proposed_fare_centavos").NonNegative(),
		field.String("status").Default("pending"),
		field.Time("created_at").Default(time.Now),
	}
}

type Bid struct {
	ent.Schema
}

func (Bid) Fields() []ent.Field {
	return []ent.Field{
		field.Int("ride_id").Positive(),
		field.Int("driver_id").Positive(),
		field.Int64("offered_fare_centavos").NonNegative(),
		field.String("status").Default("pending"),
	}
}

package schema

import (
	"entgo.io/ent"
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

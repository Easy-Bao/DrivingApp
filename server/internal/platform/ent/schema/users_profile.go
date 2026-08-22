package schema

import (
	"entgo.io/ent"
	"entgo.io/ent/schema/field"
)

type PassengerProfile struct {
	ent.Schema
}

func (PassengerProfile) Fields() []ent.Field {
	return []ent.Field{
		field.Int("user_id").Positive(),
		field.String("name"),
		field.String("address").Optional(),
		field.String("preferred_ride_type").Optional(),
	}
}

type DriverProfile struct {
	ent.Schema
}

func (DriverProfile) Fields() []ent.Field {
	return []ent.Field{
		field.Int("user_id").Positive(),
		field.String("name"),
		field.String("vehicle_type"),
		field.String("plate_number"),
		field.Float("rating").Range(0, 5).Default(0),
		field.Bool("is_online").Default(false),
		field.Int64("wallet_balance_centavos").NonNegative().Default(0),
	}
}

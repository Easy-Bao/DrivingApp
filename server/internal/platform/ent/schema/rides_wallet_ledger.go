package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
)

type WalletLedger struct {
	ent.Schema
}

func (WalletLedger) Fields() []ent.Field {
	return []ent.Field{
		field.Int("driver_id").Positive(),
		field.Int("ride_id").Positive(),
		field.Int64("amount_centavos").Positive(),
		field.Int64("commission_centavos").NonNegative(),
		field.String("kind").Default("cash_trip"),
		field.Time("created_at").Default(time.Now),
	}
}

func (WalletLedger) Indexes() []ent.Index {
	return []ent.Index{index.Fields("ride_id").Unique()}
}

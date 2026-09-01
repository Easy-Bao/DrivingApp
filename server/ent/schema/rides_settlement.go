package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/dialect/entsql"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
)

type DriverWalletAccount struct {
	ent.Schema
}

func (DriverWalletAccount) Fields() []ent.Field {
	return []ent.Field{
		field.Int("driver_id").Positive(),
		field.Int64("balance_centavos").NonNegative().Default(0),
		field.Int64("version").NonNegative().Default(0),
		field.Time("updated_at").
			Default(time.Now).
			UpdateDefault(time.Now).
			Annotations(entsql.DefaultExpr("CURRENT_TIMESTAMP")),
	}
}

func (DriverWalletAccount) Indexes() []ent.Index {
	return []ent.Index{index.Fields("driver_id").Unique()}
}

type RideSettlement struct {
	ent.Schema
}

func (RideSettlement) Fields() []ent.Field {
	return []ent.Field{
		field.Int("ride_id").Positive(),
		field.Int64("gross_fare_centavos").NonNegative(),
		field.Int64("commission_bps").Min(0).Max(10_000).Optional().Nillable(),
		field.Int64("commission_centavos").NonNegative().Default(0),
		field.Int64("driver_payout_centavos").NonNegative().Default(0),
		field.String("payment_status").Default("unpaid"),
		field.Time("cash_received_at").Optional().Nillable(),
		field.Time("settled_at").Optional().Nillable(),
		field.Time("created_at").
			Default(time.Now).
			Annotations(entsql.DefaultExpr("CURRENT_TIMESTAMP")),
		field.Time("updated_at").
			Default(time.Now).
			UpdateDefault(time.Now).
			Annotations(entsql.DefaultExpr("CURRENT_TIMESTAMP")),
	}
}

func (RideSettlement) Indexes() []ent.Index {
	return []ent.Index{
		index.Fields("ride_id").Unique(),
		index.Fields("payment_status", "updated_at"),
	}
}

package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
)

// Review belongs to the ride domain because a rating is created from a
// completed ride and contributes to driver dispatch metadata.
type Review struct {
	ent.Schema
}

func (Review) Indexes() []ent.Index {
	return []ent.Index{
		index.Fields("ride_id").Unique(),
		index.Fields("driver_id", "created_at"),
	}
}

func (Review) Fields() []ent.Field {
	return []ent.Field{
		field.Int("ride_id").Optional(),
		field.Int("driver_id").Positive(),
		field.Int("passenger_id").Positive(),
		field.String("passenger_name").Optional(),
		field.Float("rating").Range(1, 5),
		field.String("comment").Optional(),
		field.Time("created_at").Default(time.Now),
	}
}

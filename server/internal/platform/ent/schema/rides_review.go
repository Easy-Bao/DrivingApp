package schema

import (
	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"time"
)

// Review belongs to the ride domain because a rating is created from a
// completed ride and contributes to driver dispatch metadata.
type Review struct {
	ent.Schema
}

func (Review) Fields() []ent.Field {
	return []ent.Field{
		field.Int("driver_id").Positive(),
		field.Int("passenger_id").Positive(),
		field.String("passenger_name").Optional(),
		field.Float("rating").Range(1, 5),
		field.String("comment").Optional(),
		field.Time("created_at").Default(time.Now),
	}
}

package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
)

type PassengerReview struct {
	ent.Schema
}

func (PassengerReview) Fields() []ent.Field {
	return []ent.Field{
		field.Int("ride_id").Positive(),
		field.Int("driver_id").Positive(),
		field.Int("passenger_id").Positive(),
		field.Float("rating").Range(1, 5),
		field.String("comment").Optional(),
		field.Time("created_at").Default(time.Now),
	}
}

func (PassengerReview) Indexes() []ent.Index {
	return []ent.Index{
		index.Fields("ride_id").Unique(),
		index.Fields("passenger_id", "created_at"),
	}
}

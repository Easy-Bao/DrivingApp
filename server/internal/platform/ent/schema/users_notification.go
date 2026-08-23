package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
)

type Notification struct {
	ent.Schema
}

func (Notification) Indexes() []ent.Index {
	return []ent.Index{index.Fields("user_id", "created_at")}
}

func (Notification) Fields() []ent.Field {
	return []ent.Field{
		field.Int("user_id").Positive(),
		field.String("type").Default("general"),
		field.String("title"),
		field.String("body"),
		field.Bool("is_read").Default(false),
		field.Time("created_at").Default(time.Now),
	}
}

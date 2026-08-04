package schema

import (
	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"time"
)

type Notification struct {
	ent.Schema
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

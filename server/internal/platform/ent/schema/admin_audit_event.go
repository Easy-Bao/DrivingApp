package schema

import (
	"entgo.io/ent"
	"entgo.io/ent/schema/field"
)

type AuditEvent struct {
	ent.Schema
}

func (AuditEvent) Fields() []ent.Field {
	return []ent.Field{
		field.Int("actor_id").Positive(),
		field.String("action"),
		field.String("target_type"),
		field.String("target_id").Optional(),
		field.String("outcome"),
		field.String("request_id").Unique(),
	}
}

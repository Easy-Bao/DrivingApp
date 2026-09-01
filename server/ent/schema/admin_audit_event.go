package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/dialect/entsql"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
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
		field.Time("created_at").
			Default(time.Now).
			Annotations(entsql.DefaultExpr("CURRENT_TIMESTAMP")),
	}
}

func (AuditEvent) Indexes() []ent.Index {
	return []ent.Index{index.Fields("actor_id", "created_at")}
}

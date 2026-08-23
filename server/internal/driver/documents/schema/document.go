package schema

import (
	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
)

type DriverDocument struct {
	ent.Schema
}

func (DriverDocument) Indexes() []ent.Index {
	return []ent.Index{index.Fields("driver_id", "document_type")}
}

func (DriverDocument) Fields() []ent.Field {
	return []ent.Field{
		field.Int("driver_id").Positive(),
		field.String("document_type"),
		field.String("storage_key"),
		field.String("status").Default("pending"),
	}
}

package schema

import (
	"entgo.io/ent"
	"entgo.io/ent/schema/field"
)

type DriverDocument struct {
	ent.Schema
}

func (DriverDocument) Fields() []ent.Field {
	return []ent.Field{
		field.Int("driver_id").Positive(),
		field.String("document_type"),
		field.String("storage_key"),
		field.String("status").Default("pending"),
	}
}

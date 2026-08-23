package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/dialect/entsql"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
)

type DriverDocument struct {
	ent.Schema
}

func (DriverDocument) Indexes() []ent.Index {
	return []ent.Index{
		index.Fields("driver_id", "document_type", "created_at").
			StorageKey("driver_document_driver_type_created_at"),
		index.Fields("status", "created_at").
			StorageKey("driver_document_status_created_at"),
	}
}

func (DriverDocument) Fields() []ent.Field {
	return []ent.Field{
		field.Int("driver_id").Positive(),
		field.String("document_type").MaxLen(64),
		field.String("storage_key").MaxLen(160),
		field.String("status").Default("pending").MaxLen(16),
		field.String("content_type").Default("application/octet-stream").MaxLen(64),
		field.Int64("size_bytes").Default(0).NonNegative(),
		field.String("checksum_sha256").Default("").MaxLen(64),
		field.Time("created_at").
			Default(time.Now).
			Immutable().
			Annotations(entsql.DefaultExpr("CURRENT_TIMESTAMP")),
		field.Time("reviewed_at").Optional().Nillable(),
		field.Int("reviewed_by").Positive().Optional().Nillable(),
	}
}

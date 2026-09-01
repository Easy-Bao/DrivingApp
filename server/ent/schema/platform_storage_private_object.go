package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/dialect/entsql"
	"entgo.io/ent/schema/field"
)

// PrivateObject is the durable backing store for user-uploaded binary data.
// Feature tables retain ownership and workflow metadata; this table owns the
// bytes and their integrity metadata in the same PostgreSQL database.
type PrivateObject struct {
	ent.Schema
}

func (PrivateObject) Fields() []ent.Field {
	return []ent.Field{
		field.String("storage_key").Unique().Immutable().MaxLen(80),
		field.Bytes("content").NotEmpty(),
		field.String("content_type").MaxLen(128),
		field.Int64("size_bytes").Positive(),
		field.String("checksum_sha256").MinLen(64).MaxLen(64),
		field.Time("created_at").
			Default(time.Now).
			Immutable().
			Annotations(entsql.DefaultExpr("CURRENT_TIMESTAMP")),
	}
}

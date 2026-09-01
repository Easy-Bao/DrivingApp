package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
)

// RefreshSession stores only a digest of the client-held refresh token. Access
// JWTs remain stateless; these sessions provide durable rotation and revocation
// without putting bearer credentials in the database.
type RefreshSession struct {
	ent.Schema
}

func (RefreshSession) Fields() []ent.Field {
	return []ent.Field{
		field.Int("user_id").Positive(),
		field.String("token_hash").Unique().MaxLen(64),
		field.Time("expires_at"),
		field.Time("created_at").Default(time.Now).Immutable(),
		field.Time("last_used_at").Optional().Nillable(),
		field.Time("revoked_at").Optional().Nillable(),
	}
}

func (RefreshSession) Indexes() []ent.Index {
	return []ent.Index{
		index.Fields("user_id", "expires_at"),
		index.Fields("expires_at", "revoked_at"),
	}
}

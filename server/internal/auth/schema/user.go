package schema

import (
	"entgo.io/ent"
	"entgo.io/ent/schema/field"
)

// User is the shared identity record used by passenger and driver accounts.
type User struct {
	ent.Schema
}

func (User) Fields() []ent.Field {
	return []ent.Field{
		field.String("phone").Unique(),
		field.String("email").Unique(),
		field.String("password_hash"),
		field.String("role"),
		field.Bool("is_verified").Default(false),
	}
}

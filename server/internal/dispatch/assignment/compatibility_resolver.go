package assignment

import assignmentapplication "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/assignment/application"

// NewResolver constructs the legacy assignment façade around the modular use
// case implementation.
func NewResolver(routing, authority Lookup) *Resolver {
	return assignmentapplication.NewResolver(routing, authority)
}

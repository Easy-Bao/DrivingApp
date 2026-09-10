package assignment

import assignmentapplication "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/assignment/application"

func NewResolver(routing, authority Lookup) *Resolver {
	return assignmentapplication.NewResolver(routing, authority)
}

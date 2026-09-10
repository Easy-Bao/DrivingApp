package assignment

import (
	assignmentapplication "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/assignment/application"
	assignmentdomain "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/assignment/domain"
	assignmentports "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/assignment/ports"
)

// Assignment remains available at the original package path while the
// bounded-context model lives in dispatch/assignment/domain.
type Assignment = assignmentdomain.Assignment

// Lookup remains available at the original package path while the consumer
// contract lives in dispatch/assignment/ports.
type Lookup = assignmentports.Lookup

// Projection remains available at the original package path while the
// projection contract lives in dispatch/assignment/ports.
type Projection = assignmentports.Projection

// Resolver remains available at the original package path while the use case
// implementation lives in dispatch/assignment/application.
type Resolver = assignmentapplication.Resolver

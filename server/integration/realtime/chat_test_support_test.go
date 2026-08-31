//go:build integration

package realtime_test

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/assignment"
)

type chatAssignmentLookup struct {
	assignment assignment.Assignment
	found      bool
}

func (lookup chatAssignmentLookup) ForDriver(context.Context, string) ([]assignment.Assignment, error) {
	if !lookup.found {
		return nil, nil
	}
	return []assignment.Assignment{lookup.assignment}, nil
}

func (lookup chatAssignmentLookup) ForRide(context.Context, string) (assignment.Assignment, bool, error) {
	return lookup.assignment, lookup.found, nil
}

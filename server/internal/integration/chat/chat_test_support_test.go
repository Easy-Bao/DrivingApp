//go:build integration

package chat_test

import (
	"context"

	chatapplication "github.com/Easy-Bao/DrivingApp/server/internal/modules/chat/app"
)

type chatAssignmentLookup struct {
	assignment chatapplication.RideAssignment
	found      bool
}

func (lookup chatAssignmentLookup) ForRide(context.Context, string) (chatapplication.RideAssignment, bool, error) {
	return lookup.assignment, lookup.found, nil
}

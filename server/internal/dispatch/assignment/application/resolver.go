package application

import (
	"context"
	"fmt"
	"log/slog"

	assignmentdomain "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/assignment/domain"
	assignmentports "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/assignment/ports"
)

// Resolver uses the lifecycle projection for hot-path reads and consults the
// ride store when the projection has not observed the assignment yet.
type Resolver struct {
	routing   assignmentports.Lookup
	authority assignmentports.Lookup
	logger    *slog.Logger
}

func NewResolver(routing, authority assignmentports.Lookup) *Resolver {
	return &Resolver{routing: routing, authority: authority, logger: slog.Default()}
}

func (resolver *Resolver) WithLogger(logger *slog.Logger) *Resolver {
	if logger != nil {
		resolver.logger = logger
	}
	return resolver
}

func (resolver *Resolver) ForRide(ctx context.Context, rideID string) (assignmentdomain.Assignment, bool, error) {
	if resolver == nil {
		return assignmentdomain.Assignment{}, false, nil
	}
	if err := contextError(ctx); err != nil {
		return assignmentdomain.Assignment{}, false, err
	}
	if resolver.routing != nil {
		value, found, err := resolver.routing.ForRide(ctx, rideID)
		if err == nil && found {
			return value, true, nil
		}
		if contextErr := contextError(ctx); contextErr != nil {
			return assignmentdomain.Assignment{}, false, contextErr
		}
		if err != nil {
			if resolver.authority == nil {
				return assignmentdomain.Assignment{}, false, fmt.Errorf("load routing ride assignment: %w", err)
			}
			resolver.log().DebugContext(ctx, "routing ride assignment lookup failed; using authority", "error", err)
		}
	}
	if err := contextError(ctx); err != nil {
		return assignmentdomain.Assignment{}, false, err
	}
	if resolver.authority == nil {
		return assignmentdomain.Assignment{}, false, nil
	}
	value, found, err := resolver.authority.ForRide(ctx, rideID)
	if err != nil {
		return assignmentdomain.Assignment{}, false, fmt.Errorf("load authoritative ride assignment: %w", err)
	}
	if err := contextError(ctx); err != nil {
		return assignmentdomain.Assignment{}, false, err
	}
	if found {
		resolver.remember(value.DriverID, []assignmentdomain.Assignment{value})
	}
	return value, found, nil
}

func (resolver *Resolver) ForDriver(ctx context.Context, driverID string) ([]assignmentdomain.Assignment, error) {
	if resolver == nil {
		return []assignmentdomain.Assignment{}, nil
	}
	if err := contextError(ctx); err != nil {
		return nil, err
	}
	if resolver.routing != nil {
		assignments, err := resolver.routing.ForDriver(ctx, driverID)
		if err == nil && len(assignments) > 0 {
			return assignments, nil
		}
		if contextErr := contextError(ctx); contextErr != nil {
			return nil, contextErr
		}
		if err != nil && resolver.authority == nil {
			return nil, fmt.Errorf("load routing driver assignments: %w", err)
		}
		if err != nil {
			resolver.log().DebugContext(ctx, "routing driver assignment lookup failed; using authority", "error", err)
		}
	}
	if err := contextError(ctx); err != nil {
		return nil, err
	}
	if resolver.authority != nil {
		assignments, err := resolver.authority.ForDriver(ctx, driverID)
		if err == nil {
			if contextErr := contextError(ctx); contextErr != nil {
				return nil, contextErr
			}
			resolver.remember(driverID, assignments)
		}
		if err != nil {
			return nil, fmt.Errorf("load authoritative driver assignments: %w", err)
		}
		return assignments, nil
	}
	return []assignmentdomain.Assignment{}, nil
}

func (resolver *Resolver) remember(driverID string, assignments []assignmentdomain.Assignment) {
	if resolver == nil || resolver.routing == nil {
		return
	}
	projection, ok := resolver.routing.(assignmentports.Projection)
	if ok {
		projection.Remember(driverID, assignments)
	}
}

func (resolver *Resolver) log() *slog.Logger {
	if resolver != nil && resolver.logger != nil {
		return resolver.logger
	}
	return slog.Default()
}

func contextError(ctx context.Context) error {
	if ctx == nil {
		return nil
	}
	return ctx.Err()
}

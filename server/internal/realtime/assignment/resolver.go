package assignment

import "context"

// Resolver uses the lifecycle projection for hot-path reads and consults the
// ride store when the projection has not observed the assignment yet.
type Resolver struct {
	routing   Lookup
	authority Lookup
}

func NewResolver(routing, authority Lookup) *Resolver {
	return &Resolver{routing: routing, authority: authority}
}

func (resolver *Resolver) ForRide(ctx context.Context, rideID string) (Assignment, bool, error) {
	if resolver == nil {
		return Assignment{}, false, nil
	}
	if resolver.routing != nil {
		value, found, err := resolver.routing.ForRide(ctx, rideID)
		if err == nil && found {
			return value, true, nil
		}
		if err != nil && resolver.authority == nil {
			return Assignment{}, false, err
		}
	}
	if resolver.authority == nil {
		return Assignment{}, false, nil
	}
	value, found, err := resolver.authority.ForRide(ctx, rideID)
	if err != nil {
		return Assignment{}, false, err
	}
	if found {
		resolver.remember(value.DriverID, []Assignment{value})
	}
	return value, found, nil
}

func (resolver *Resolver) ForDriver(ctx context.Context, driverID string) ([]Assignment, error) {
	if resolver != nil && resolver.routing != nil {
		assignments, err := resolver.routing.ForDriver(ctx, driverID)
		if err == nil && len(assignments) > 0 {
			return assignments, nil
		}
	}
	if resolver != nil && resolver.authority != nil {
		assignments, err := resolver.authority.ForDriver(ctx, driverID)
		if err == nil {
			resolver.remember(driverID, assignments)
		}
		return assignments, err
	}
	return nil, nil
}

func (resolver *Resolver) remember(driverID string, assignments []Assignment) {
	if resolver == nil || resolver.routing == nil {
		return
	}
	projection, ok := resolver.routing.(Projection)
	if ok {
		projection.Remember(driverID, assignments)
	}
}

package assignment

import "context"

// Resolver keeps authorization on the ride store while allowing the routing
// cache to avoid repeated fan-out lookups for driver location events.
type Resolver struct {
	routing   Lookup
	authority Lookup
}

func NewResolver(routing, authority Lookup) *Resolver {
	return &Resolver{routing: routing, authority: authority}
}

func (resolver *Resolver) ForRide(ctx context.Context, rideID string) (Assignment, bool, error) {
	if resolver != nil && resolver.authority != nil {
		return resolver.authority.ForRide(ctx, rideID)
	}
	if resolver != nil && resolver.routing != nil {
		return resolver.routing.ForRide(ctx, rideID)
	}
	return Assignment{}, false, nil
}

func (resolver *Resolver) ForDriver(ctx context.Context, driverID string) ([]Assignment, error) {
	if resolver != nil && resolver.routing != nil {
		assignments, err := resolver.routing.ForDriver(ctx, driverID)
		if err == nil && len(assignments) > 0 {
			return assignments, nil
		}
	}
	if resolver != nil && resolver.authority != nil {
		return resolver.authority.ForDriver(ctx, driverID)
	}
	return nil, nil
}

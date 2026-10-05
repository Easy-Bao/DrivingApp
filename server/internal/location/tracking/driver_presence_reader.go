package tracking

import "context"

// DriverPresenceReader is the server-owned availability check used before
// accepting driver telemetry. The mobile client's online flag is not an
// authority for publishing location.
type DriverPresenceReader interface {
	IsOnline(ctx context.Context, driverID string) (bool, error)
}

type DriverPresenceReaderFunc func(context.Context, string) (bool, error)

func (reader DriverPresenceReaderFunc) IsOnline(
	ctx context.Context,
	driverID string,
) (bool, error) {
	return reader(ctx, driverID)
}

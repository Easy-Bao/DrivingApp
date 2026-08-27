package migration

import (
	"context"

	"entgo.io/ent/dialect"
)

func applyRideStateConstraints(ctx context.Context, connection dialect.ExecQuerier) error {
	return executeStatements(ctx, connection, rideStateConstraintStatements)
}

var rideStateConstraintStatements = []string{
	`UPDATE rides SET status = 'cancelled' WHERE status = 'canceled'`,
	`UPDATE bid_sessions SET status = 'cancelled' WHERE status = 'canceled'`,
	`ALTER TABLE rides DROP CONSTRAINT IF EXISTS rides_status_check`,
	`ALTER TABLE rides ADD CONSTRAINT rides_status_check CHECK (status IN ('requested', 'assigned', 'accepted', 'arrived', 'in_transit', 'completed', 'cancelled')) NOT VALID`,
	`ALTER TABLE rides VALIDATE CONSTRAINT rides_status_check`,
	`ALTER TABLE rides DROP CONSTRAINT IF EXISTS rides_driver_assignment_check`,
	`ALTER TABLE rides ADD CONSTRAINT rides_driver_assignment_check CHECK (status IN ('requested', 'cancelled') OR (driver_id IS NOT NULL AND driver_id > 0)) NOT VALID`,
	`ALTER TABLE rides VALIDATE CONSTRAINT rides_driver_assignment_check`,
	`ALTER TABLE rides DROP CONSTRAINT IF EXISTS rides_payment_status_check`,
	`ALTER TABLE rides ADD CONSTRAINT rides_payment_status_check CHECK (payment_status IN ('unpaid', 'paid')) NOT VALID`,
	`ALTER TABLE rides VALIDATE CONSTRAINT rides_payment_status_check`,
	`ALTER TABLE bid_sessions DROP CONSTRAINT IF EXISTS bid_sessions_status_check`,
	`ALTER TABLE bid_sessions ADD CONSTRAINT bid_sessions_status_check CHECK (status IN ('open', 'accepted', 'cancelled', 'expired')) NOT VALID`,
	`ALTER TABLE bid_sessions VALIDATE CONSTRAINT bid_sessions_status_check`,
	`ALTER TABLE bid_offers DROP CONSTRAINT IF EXISTS bid_offers_status_check`,
	`ALTER TABLE bid_offers ADD CONSTRAINT bid_offers_status_check CHECK (status IN ('pending', 'accepted', 'rejected')) NOT VALID`,
	`ALTER TABLE bid_offers VALIDATE CONSTRAINT bid_offers_status_check`,
	`ALTER TABLE bids DROP CONSTRAINT IF EXISTS bids_status_check`,
	`ALTER TABLE bids ADD CONSTRAINT bids_status_check CHECK (status IN ('pending', 'accepted', 'rejected')) NOT VALID`,
	`ALTER TABLE bids VALIDATE CONSTRAINT bids_status_check`,
	`ALTER TABLE ride_settlements DROP CONSTRAINT IF EXISTS ride_settlements_payment_status_check`,
	`ALTER TABLE ride_settlements ADD CONSTRAINT ride_settlements_payment_status_check CHECK (payment_status IN ('unpaid', 'paid')) NOT VALID`,
	`ALTER TABLE ride_settlements VALIDATE CONSTRAINT ride_settlements_payment_status_check`,
}

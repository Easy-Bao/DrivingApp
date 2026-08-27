package migration

import (
	"context"
	"fmt"

	"github.com/Easy-Bao/DrivingApp/server/ent"
)

// ValidateEntSchema executes zero-row queries for every generated entity. The
// queries are read-only, but they select the complete generated field set, so
// a deployed binary cannot start against a database that is missing a newly
// generated column.
func ValidateEntSchema(ctx context.Context, client *ent.Client) error {
	if client == nil {
		return fmt.Errorf("schema client is required")
	}

	checks := []struct {
		name  string
		check func() error
	}{
		{name: "users", check: func() error {
			_, err := client.User.Query().Limit(0).All(ctx)
			return err
		}},
		{name: "refresh_sessions", check: func() error {
			_, err := client.RefreshSession.Query().Limit(0).All(ctx)
			return err
		}},
		{name: "driver_profiles", check: func() error {
			_, err := client.DriverProfile.Query().Limit(0).All(ctx)
			return err
		}},
		{name: "passenger_profiles", check: func() error {
			_, err := client.PassengerProfile.Query().Limit(0).All(ctx)
			return err
		}},
		{name: "rides", check: func() error {
			_, err := client.Ride.Query().Limit(0).All(ctx)
			return err
		}},
		{name: "bid_sessions", check: func() error {
			_, err := client.BidSession.Query().Limit(0).All(ctx)
			return err
		}},
		{name: "bid_offers", check: func() error {
			_, err := client.BidOffer.Query().Limit(0).All(ctx)
			return err
		}},
		{name: "bids", check: func() error {
			_, err := client.Bid.Query().Limit(0).All(ctx)
			return err
		}},
		{name: "reviews", check: func() error {
			_, err := client.Review.Query().Limit(0).All(ctx)
			return err
		}},
		{name: "passenger_reviews", check: func() error {
			_, err := client.PassengerReview.Query().Limit(0).All(ctx)
			return err
		}},
		{name: "notifications", check: func() error {
			_, err := client.Notification.Query().Limit(0).All(ctx)
			return err
		}},
		{name: "driver_documents", check: func() error {
			_, err := client.DriverDocument.Query().Limit(0).All(ctx)
			return err
		}},
		{name: "driver_wallet_accounts", check: func() error {
			_, err := client.DriverWalletAccount.Query().Limit(0).All(ctx)
			return err
		}},
		{name: "ride_settlements", check: func() error {
			_, err := client.RideSettlement.Query().Limit(0).All(ctx)
			return err
		}},
		{name: "wallet_ledgers", check: func() error {
			_, err := client.WalletLedger.Query().Limit(0).All(ctx)
			return err
		}},
		{name: "audit_events", check: func() error {
			_, err := client.AuditEvent.Query().Limit(0).All(ctx)
			return err
		}},
		{name: "private_objects", check: func() error {
			_, err := client.PrivateObject.Query().Limit(0).All(ctx)
			return err
		}},
	}

	for _, check := range checks {
		if err := check.check(); err != nil {
			return fmt.Errorf("validate %s schema: %w", check.name, err)
		}
	}
	return nil
}

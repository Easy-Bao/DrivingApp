package postgres

import (
	"errors"
	"fmt"
	"time"

	dispatchdomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/dispatch/domain"
	ridedomain "github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/sqlc"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
)

const _maxPostgresRideID = 1<<31 - 1

func fromPostgresBidSession(item databasepostgres.BidSession) (dispatchdomain.BidSession, error) {
	if !item.ExpiresAt.Valid {
		return dispatchdomain.BidSession{}, errors.New("bid session expiration time is null")
	}
	if !item.CreatedAt.Valid {
		return dispatchdomain.BidSession{}, errors.New("bid session creation time is null")
	}
	var targetDriverID, acceptedDriverID *int
	if item.TargetDriverID.Valid && item.TargetDriverID.Int32 > 0 {
		value := int(item.TargetDriverID.Int32)
		targetDriverID = &value
	}
	if item.AcceptedDriverID.Valid && item.AcceptedDriverID.Int32 > 0 {
		value := int(item.AcceptedDriverID.Int32)
		acceptedDriverID = &value
	}
	return dispatchdomain.BidSession{
		ID:                int(item.ID),
		PassengerID:       int(item.PassengerID),
		RideType:          item.RideType,
		PickupLatitude:    item.PickupLatitude,
		PickupLongitude:   item.PickupLongitude,
		PickupName:        item.PickupName,
		DropoffLatitude:   item.DropoffLatitude,
		DropoffLongitude:  item.DropoffLongitude,
		DropoffName:       item.DropoffName,
		PassengerNote:     bidTextValue(item.PassengerNote),
		DistanceKm:        item.DistanceKm,
		DurationMinutes:   item.DurationMinutes,
		OfferedFareAmount: item.OfferedFare,
		Status:            item.Status,
		TargetDriverID:    targetDriverID,
		AcceptedDriverID:  acceptedDriverID,
		ExpiresAt:         item.ExpiresAt.Time,
		CreatedAt:         item.CreatedAt.Time,
	}, nil
}

func fromPostgresBidOffer(item databasepostgres.BidOffer) (dispatchdomain.BidOffer, error) {
	if !item.CreatedAt.Valid {
		return dispatchdomain.BidOffer{}, errors.New("bid offer creation time is null")
	}
	return dispatchdomain.BidOffer{
		ID:                 int64(item.ID),
		SessionID:          int(item.SessionID),
		DriverID:           int(item.DriverID),
		DriverName:         bidTextValue(item.DriverName),
		PlateNumber:        bidTextValue(item.PlateNumber),
		VehicleType:        bidTextValue(item.VehicleType),
		ProposedFareAmount: item.ProposedFare,
		Status:             item.Status,
		CreatedAt:          item.CreatedAt.Time,
	}, nil
}

func fromPostgresActiveRideRow(item databasepostgres.ListActiveRidesForDriverRow) (ridedomain.Ride, error) {
	return fromPostgresRideProjection(item.Ride, rideSettlementProjection{
		PaymentStatus:      item.PaymentStatus,
		CashReceivedAmount: item.CashReceivedAmount,
		CashChangeAmount:   item.CashChangeAmount,
		CashOutcome:        item.CashOutcome,
		CommissionBps:      item.CommissionBps,
		CommissionAmount:   item.CommissionAmount,
		DriverPayoutAmount: item.DriverPayoutAmount,
	})
}

func fromPostgresBidSessionRideRow(item databasepostgres.GetRideByBidSessionIDRow) (ridedomain.Ride, error) {
	return fromPostgresRideProjection(item.Ride, rideSettlementProjection{
		PaymentStatus:      item.PaymentStatus,
		CashReceivedAmount: item.CashReceivedAmount,
		CashChangeAmount:   item.CashChangeAmount,
		CashOutcome:        item.CashOutcome,
		CommissionBps:      item.CommissionBps,
		CommissionAmount:   item.CommissionAmount,
		DriverPayoutAmount: item.DriverPayoutAmount,
	})
}

func fromPostgresAcceptedRideProjection(
	item databasepostgres.Ride,
	settlement databasepostgres.RideSettlement,
) (ridedomain.Ride, error) {
	return fromPostgresRideProjection(item, rideSettlementProjection{
		PaymentStatus:      settlement.PaymentStatus,
		CashReceivedAmount: settlement.CashReceivedAmount,
		CashChangeAmount:   settlement.CashChangeAmount,
		CashOutcome:        settlement.CashOutcome,
		CommissionBps:      settlement.CommissionBps,
		CommissionAmount:   settlement.CommissionAmount,
		DriverPayoutAmount: settlement.DriverPayoutAmount,
	})
}

type rideSettlementProjection struct {
	PaymentStatus      string
	CashReceivedAmount int64
	CashChangeAmount   int64
	CashOutcome        string
	CommissionBps      pgtype.Int4
	CommissionAmount   int64
	DriverPayoutAmount int64
}

func fromPostgresRideProjection(
	item databasepostgres.Ride,
	projection rideSettlementProjection,
) (ridedomain.Ride, error) {
	if !item.CreatedAt.Valid {
		return ridedomain.Ride{}, errors.New("ride creation time is null")
	}
	var driverID *int
	if item.DriverID.Valid && item.DriverID.Int32 > 0 {
		value := int(item.DriverID.Int32)
		driverID = &value
	}
	ride := ridedomain.Ride{
		ID:                         int(item.ID),
		PassengerID:                int(item.PassengerID),
		DriverID:                   driverID,
		Status:                     item.Status,
		FareAmount:                 item.FareAmount,
		RideType:                   item.RideType,
		PickupLatitude:             dispatchFloatValue(item.PickupLatitude),
		PickupLongitude:            dispatchFloatValue(item.PickupLongitude),
		PickupName:                 dispatchTextValue(item.PickupName),
		DropoffLatitude:            dispatchFloatValue(item.DropoffLatitude),
		DropoffLongitude:           dispatchFloatValue(item.DropoffLongitude),
		DropoffName:                dispatchTextValue(item.DropoffName),
		DistanceKm:                 dispatchFloatValue(item.DistanceKm),
		DurationMinutes:            dispatchFloatValue(item.DurationMinutes),
		DriverName:                 dispatchTextValue(item.DriverName),
		VehicleType:                dispatchTextValue(item.VehicleType),
		PlateNumber:                dispatchTextValue(item.PlateNumber),
		DriverRating:               dispatchFloatValue(item.DriverRating),
		CreatedAt:                  dispatchTimestamp(item.CreatedAt),
		CompletedAt:                dispatchTimestamp(item.CompletedAt),
		ArrivedAt:                  dispatchTimestamp(item.ArrivedAt),
		WaitingUntil:               dispatchTimestamp(item.WaitingUntil),
		PaymentStatus:              "unpaid",
		CashOutcome:                string(ridedomain.CashOutcomeUnpaid),
		CancelledBy:                dispatchOptionalInt(item.CancelledBy),
		CancellationReason:         item.CancellationReason,
		CancellationResponsibility: item.CancellationResponsibility,
		CancellationDetails:        item.CancellationDetails,
	}
	if projection.PaymentStatus != "" {
		ride.PaymentStatus = projection.PaymentStatus
	}
	ride.CashReceivedAmount = projection.CashReceivedAmount
	ride.CashChangeAmount = projection.CashChangeAmount
	if projection.CashOutcome != "" {
		ride.CashOutcome = projection.CashOutcome
	}
	if projection.CommissionBps.Valid {
		commissionBps := int64(projection.CommissionBps.Int32)
		ride.CommissionBPS = &commissionBps
	}
	ride.CommissionAmount = projection.CommissionAmount
	ride.DriverPayoutAmount = projection.DriverPayoutAmount
	return ride, nil
}

func bidTimestamp(value time.Time) pgtype.Timestamptz {
	return pgtype.Timestamptz{Time: value, Valid: true}
}

func toPostgresBidText(value string) pgtype.Text {
	return pgtype.Text{String: value, Valid: true}
}

func bidTextValue(value pgtype.Text) string {
	if !value.Valid {
		return ""
	}
	return value.String
}

func dispatchTimestamp(value pgtype.Timestamptz) *string {
	if !value.Valid {
		return nil
	}
	formatted := value.Time.UTC().Format(time.RFC3339)
	return &formatted
}

func dispatchTextValue(value pgtype.Text) string {
	if !value.Valid {
		return ""
	}
	return value.String
}

func dispatchFloatValue(value pgtype.Float8) float64 {
	if !value.Valid {
		return 0
	}
	return value.Float64
}

func dispatchOptionalInt(value pgtype.Int4) *int {
	if !value.Valid || value.Int32 <= 0 {
		return nil
	}
	result := int(value.Int32)
	return &result
}

func toPostgresRideID(value int, field string) (int32, error) {
	if value <= 0 || int64(value) > int64(_maxPostgresRideID) {
		return 0, fmt.Errorf("%s %d is outside PostgreSQL integer range", field, value)
	}
	return int32(value), nil
}

func isPostgresUniqueViolation(err error) bool {
	var databaseError *pgconn.PgError
	return errors.As(err, &databaseError) && databaseError.Code == "23505"
}

func driverUnavailableError(operation string, err error, unavailable error) error {
	if errors.Is(err, pgx.ErrNoRows) {
		return unavailable
	}
	return fmt.Errorf("%s: %w", operation, err)
}

func acceptedRideConflictError(operation string, err error) error {
	var databaseError *pgconn.PgError
	if errors.As(err, &databaseError) && databaseError.Code == "23505" {
		switch databaseError.ConstraintName {
		case "ride_passenger_id", "rides_one_active_ride_per_passenger_idx":
			return ridedomain.ErrActiveBooking
		case "rides_one_active_ride_per_driver_idx":
			return ridedomain.ErrDriverHasActiveRide
		}
	}
	return fmt.Errorf("%s: %w", operation, err)
}

func rideFloat(value float64) pgtype.Float8 {
	return pgtype.Float8{Float64: value, Valid: true}
}

func rideRating(value float64) pgtype.Float8 {
	if value <= 0 {
		return pgtype.Float8{}
	}
	return pgtype.Float8{Float64: value, Valid: true}
}

func rideText(value string) pgtype.Text {
	return pgtype.Text{String: value, Valid: true}
}

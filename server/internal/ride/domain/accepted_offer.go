package domain

type DriverAssignmentSnapshot struct {
	Name        string
	VehicleType string
	PlateNumber string
}

func NewRideFromAcceptedOffer(
	session BidSession,
	offer BidOffer,
	driver DriverAssignmentSnapshot,
	commissionBPS int64,
) (Ride, error) {
	invalidSession := session.ID <= 0 || session.PassengerID <= 0
	invalidOffer := offer.DriverID <= 0 || offer.SessionID != session.ID
	if invalidSession || invalidOffer {
		return Ride{}, ErrInvalidTrip
	}

	settlement, err := NewSettlementSnapshot(
		offer.ProposedFareAmount,
		commissionBPS,
	)
	if err != nil {
		return Ride{}, err
	}

	driverID := offer.DriverID
	return Ride{
		PassengerID:        session.PassengerID,
		DriverID:           &driverID,
		Status:             "accepted",
		FareAmount:         settlement.FareAmount,
		RideType:           session.RideType,
		PickupLatitude:     session.PickupLatitude,
		PickupLongitude:    session.PickupLongitude,
		PickupName:         session.PickupName,
		DropoffLatitude:    session.DropoffLatitude,
		DropoffLongitude:   session.DropoffLongitude,
		DropoffName:        session.DropoffName,
		DistanceKm:         session.DistanceKm,
		DurationMinutes:    session.DurationMinutes,
		DriverName:         driver.Name,
		VehicleType:        driver.VehicleType,
		PlateNumber:        driver.PlateNumber,
		CommissionBPS:      &settlement.CommissionBPS,
		CommissionAmount:   settlement.CommissionAmount,
		DriverPayoutAmount: settlement.DriverPayoutAmount,
	}, nil
}

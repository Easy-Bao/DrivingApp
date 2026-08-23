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
	if session.ID <= 0 || session.PassengerID <= 0 || offer.DriverID <= 0 ||
		offer.SessionID != session.ID {
		return Ride{}, ErrInvalidTrip
	}

	settlement, err := NewSettlementSnapshot(
		offer.ProposedFareCentavos,
		commissionBPS,
	)
	if err != nil {
		return Ride{}, err
	}

	driverID := offer.DriverID
	return Ride{
		PassengerID:          session.PassengerID,
		DriverID:             &driverID,
		Status:               "accepted",
		FareCentavos:         settlement.FareCentavos,
		RideType:             session.RideType,
		PickupLatitude:       session.PickupLatitude,
		PickupLongitude:      session.PickupLongitude,
		PickupName:           session.PickupName,
		DropoffLatitude:      session.DropoffLatitude,
		DropoffLongitude:     session.DropoffLongitude,
		DropoffName:          session.DropoffName,
		DistanceKm:           session.DistanceKm,
		DurationMinutes:      session.DurationMinutes,
		DriverName:           driver.Name,
		VehicleType:          driver.VehicleType,
		PlateNumber:          driver.PlateNumber,
		CommissionBPS:        &settlement.CommissionBPS,
		CommissionCentavos:   settlement.CommissionCentavos,
		DriverPayoutCentavos: settlement.DriverPayoutCentavos,
	}, nil
}

package domain

type DriverAssignmentSnapshot struct {
	Name        string
	VehicleType string
	PlateNumber string
}

func NewAcceptedRide(
	ride Ride,
	driver DriverAssignmentSnapshot,
	commissionBPS int64,
) (Ride, error) {
	if ride.PassengerID <= 0 || ride.DriverID == nil || *ride.DriverID <= 0 || ride.FareAmount <= 0 {
		return Ride{}, ErrInvalidTrip
	}

	settlement, err := NewSettlementSnapshot(
		ride.FareAmount,
		commissionBPS,
	)
	if err != nil {
		return Ride{}, err
	}

	ride.Status = "accepted"
	ride.DriverName = driver.Name
	ride.VehicleType = driver.VehicleType
	ride.PlateNumber = driver.PlateNumber
	ride.CommissionBPS = &settlement.CommissionBPS
	ride.CommissionAmount = settlement.CommissionAmount
	ride.DriverPayoutAmount = settlement.DriverPayoutAmount
	return ride, nil
}

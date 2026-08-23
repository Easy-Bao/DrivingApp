package domain

import "math"

type SettlementSnapshot struct {
	FareCentavos         int64
	CommissionBPS        int64
	CommissionCentavos   int64
	DriverPayoutCentavos int64
}

func NewSettlementSnapshot(fareCentavos, commissionBPS int64) (SettlementSnapshot, error) {
	if fareCentavos <= 0 || commissionBPS < 0 || commissionBPS > 10_000 {
		return SettlementSnapshot{}, ErrInvalidSettlement
	}
	if commissionBPS != 0 && fareCentavos > math.MaxInt64/commissionBPS {
		return SettlementSnapshot{}, ErrInvalidSettlement
	}

	commissionCentavos := fareCentavos * commissionBPS / 10_000
	return SettlementSnapshot{
		FareCentavos:         fareCentavos,
		CommissionBPS:        commissionBPS,
		CommissionCentavos:   commissionCentavos,
		DriverPayoutCentavos: fareCentavos - commissionCentavos,
	}, nil
}

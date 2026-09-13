package domain

import "math"

type SettlementSnapshot struct {
	FareAmount         int64
	CommissionBPS      int64
	CommissionAmount   int64
	DriverPayoutAmount int64
}

func NewSettlementSnapshot(fareAmount, commissionBPS int64) (SettlementSnapshot, error) {
	invalidFare := fareAmount <= 0
	invalidCommission := commissionBPS < 0 || commissionBPS > 10_000
	if invalidFare || invalidCommission {
		return SettlementSnapshot{}, ErrInvalidSettlement
	}
	if commissionBPS != 0 && fareAmount > math.MaxInt64/commissionBPS {
		return SettlementSnapshot{}, ErrInvalidSettlement
	}

	commissionAmount := fareAmount * commissionBPS / 10_000
	return SettlementSnapshot{
		FareAmount:         fareAmount,
		CommissionBPS:      commissionBPS,
		CommissionAmount:   commissionAmount,
		DriverPayoutAmount: fareAmount - commissionAmount,
	}, nil
}

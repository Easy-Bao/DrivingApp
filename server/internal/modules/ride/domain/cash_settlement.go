package domain

// CashOutcome describes the result of the driver's physical cash collection.
type CashOutcome string

const (
	CashOutcomePaid     CashOutcome = "paid"
	CashOutcomePartial  CashOutcome = "partial"
	CashOutcomeRefused  CashOutcome = "refused"
	CashOutcomeUnpaid   CashOutcome = "unpaid"
	CashOutcomeDisputed CashOutcome = "disputed"
)

// CashSettlementRequest is the driver command recorded for a completed cash
// ride. ReceivedAmount is the tendered amount before change is returned.
type CashSettlementRequest struct {
	RideID         int
	DriverID       int
	ReceivedAmount int64
	ChangeAmount   int64
	Outcome        CashOutcome
}

// CashSettlement contains the validated cash result and the internal ledger
// economics derived from cash that was actually retained by the driver.
type CashSettlement struct {
	Outcome         CashOutcome
	ReceivedAmount  int64
	ChangeAmount    int64
	CollectedAmount int64
	PaymentStatus   string
	Snapshot        SettlementSnapshot
}

// NewCashSettlement validates a cash collection against the authoritative
// fare. A paid ride must net exactly the fare after change; a partial ride is
// recorded as an unresolved cash exception and cannot silently become paid.
func NewCashSettlement(
	fareAmount int64,
	receivedAmount int64,
	changeAmount int64,
	outcome CashOutcome,
	commissionBPS int64,
) (CashSettlement, error) {
	if fareAmount <= 0 || receivedAmount < 0 || changeAmount < 0 || changeAmount > receivedAmount {
		return CashSettlement{}, ErrInvalidSettlement
	}
	collectedAmount := receivedAmount - changeAmount
	switch outcome {
	case CashOutcomePaid:
		if collectedAmount != fareAmount {
			return CashSettlement{}, ErrInvalidSettlement
		}
	case CashOutcomePartial:
		if collectedAmount <= 0 || collectedAmount >= fareAmount || changeAmount != 0 {
			return CashSettlement{}, ErrInvalidSettlement
		}
	case CashOutcomeRefused, CashOutcomeUnpaid:
		if collectedAmount != 0 {
			return CashSettlement{}, ErrInvalidSettlement
		}
	default:
		return CashSettlement{}, ErrInvalidSettlement
	}

	snapshot := SettlementSnapshot{}
	if collectedAmount > 0 {
		var err error
		snapshot, err = NewSettlementSnapshot(collectedAmount, commissionBPS)
		if err != nil {
			return CashSettlement{}, err
		}
	}
	paymentStatus := "unpaid"
	if outcome == CashOutcomePaid {
		paymentStatus = "paid"
	}
	return CashSettlement{
		Outcome:         outcome,
		ReceivedAmount:  receivedAmount,
		ChangeAmount:    changeAmount,
		CollectedAmount: collectedAmount,
		PaymentStatus:   paymentStatus,
		Snapshot:        snapshot,
	}, nil
}

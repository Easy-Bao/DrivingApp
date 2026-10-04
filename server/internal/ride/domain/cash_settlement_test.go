package domain

import "testing"

func TestNewCashSettlement(t *testing.T) {
	tests := []struct {
		name             string
		fare             int64
		received         int64
		change           int64
		outcome          CashOutcome
		wantCollected    int64
		wantPaymentState string
		wantPayout       int64
		wantErr          bool
	}{
		{
			name:             "exact cash paid",
			fare:             5000,
			received:         5000,
			outcome:          CashOutcomePaid,
			wantCollected:    5000,
			wantPaymentState: "paid",
			wantPayout:       5000,
		},
		{
			name:             "cash paid with change",
			fare:             5000,
			received:         10000,
			change:           5000,
			outcome:          CashOutcomePaid,
			wantCollected:    5000,
			wantPaymentState: "paid",
			wantPayout:       5000,
		},
		{
			name:             "partial cash remains unpaid",
			fare:             5000,
			received:         2000,
			outcome:          CashOutcomePartial,
			wantCollected:    2000,
			wantPaymentState: "unpaid",
			wantPayout:       2000,
		},
		{
			name:             "cash refused",
			fare:             5000,
			outcome:          CashOutcomeRefused,
			wantPaymentState: "unpaid",
		},
		{
			name:     "paid amount must net to fare",
			fare:     5000,
			received: 6000,
			outcome:  CashOutcomePaid,
			wantErr:  true,
		},
		{
			name:     "change cannot exceed received cash",
			fare:     5000,
			received: 1000,
			change:   1500,
			outcome:  CashOutcomePaid,
			wantErr:  true,
		},
		{
			name:     "partial cash cannot include change",
			fare:     5000,
			received: 3000,
			change:   1000,
			outcome:  CashOutcomePartial,
			wantErr:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			settlement, err := NewCashSettlement(tt.fare, tt.received, tt.change, tt.outcome, 0)
			if (err != nil) != tt.wantErr {
				t.Fatalf("NewCashSettlement() error = %v, wantErr %t", err, tt.wantErr)
			}
			if tt.wantErr {
				return
			}
			if settlement.CollectedAmount != tt.wantCollected {
				t.Fatalf("collected amount = %d, want %d", settlement.CollectedAmount, tt.wantCollected)
			}
			if settlement.PaymentStatus != tt.wantPaymentState {
				t.Fatalf("payment status = %q, want %q", settlement.PaymentStatus, tt.wantPaymentState)
			}
			if settlement.Snapshot.DriverPayoutAmount != tt.wantPayout {
				t.Fatalf("driver payout = %d, want %d", settlement.Snapshot.DriverPayoutAmount, tt.wantPayout)
			}
		})
	}
}

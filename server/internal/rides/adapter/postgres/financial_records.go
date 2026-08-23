package postgres

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/ent/driverwalletaccount"
	"github.com/Easy-Bao/DrivingApp/server/ent/ridesettlement"
	"github.com/Easy-Bao/DrivingApp/server/internal/rides/domain"
)

func createRideSettlement(
	ctx context.Context,
	transaction *ent.Tx,
	rideID int,
	snapshot domain.SettlementSnapshot,
) error {
	_, err := transaction.RideSettlement.Create().
		SetRideID(rideID).
		SetGrossFareCentavos(snapshot.FareCentavos).
		SetCommissionBps(snapshot.CommissionBPS).
		SetCommissionCentavos(snapshot.CommissionCentavos).
		SetDriverPayoutCentavos(snapshot.DriverPayoutCentavos).
		SetPaymentStatus("unpaid").
		Save(ctx)
	return err
}

func ensureRideSettlement(
	ctx context.Context,
	transaction *ent.Tx,
	rideItem *ent.Ride,
	legacyCommissionBPS int64,
) (*ent.RideSettlement, domain.SettlementSnapshot, error) {
	item, err := transaction.RideSettlement.Query().
		Where(ridesettlement.RideIDEQ(rideItem.ID)).
		Only(ctx)
	if err != nil && !ent.IsNotFound(err) {
		return nil, domain.SettlementSnapshot{}, err
	}

	commissionBPS := legacyCommissionBPS
	if item != nil && item.CommissionBps != nil {
		commissionBPS = *item.CommissionBps
	} else if rideItem.CommissionBps != nil {
		commissionBPS = *rideItem.CommissionBps
	}
	snapshot, err := domain.NewSettlementSnapshot(rideItem.FareCentavos, commissionBPS)
	if err != nil {
		return nil, domain.SettlementSnapshot{}, err
	}

	if item == nil {
		builder := transaction.RideSettlement.Create().
			SetRideID(rideItem.ID).
			SetGrossFareCentavos(snapshot.FareCentavos).
			SetCommissionBps(snapshot.CommissionBPS).
			SetCommissionCentavos(snapshot.CommissionCentavos).
			SetDriverPayoutCentavos(snapshot.DriverPayoutCentavos).
			SetPaymentStatus(rideItem.PaymentStatus)
		if !rideItem.CashReceivedAt.IsZero() {
			builder.SetCashReceivedAt(rideItem.CashReceivedAt).
				SetSettledAt(rideItem.CashReceivedAt)
		}
		item, err = builder.Save(ctx)
		return item, snapshot, err
	}
	if item.GrossFareCentavos != snapshot.FareCentavos {
		return nil, domain.SettlementSnapshot{}, domain.ErrInvalidSettlement
	}
	if item.CommissionBps != nil &&
		(item.CommissionCentavos != snapshot.CommissionCentavos ||
			item.DriverPayoutCentavos != snapshot.DriverPayoutCentavos) {
		return nil, domain.SettlementSnapshot{}, domain.ErrInvalidSettlement
	}
	if item.CommissionBps == nil && item.PaymentStatus != "paid" {
		item, err = item.Update().
			SetCommissionBps(snapshot.CommissionBPS).
			SetCommissionCentavos(snapshot.CommissionCentavos).
			SetDriverPayoutCentavos(snapshot.DriverPayoutCentavos).
			Save(ctx)
		if err != nil {
			return nil, domain.SettlementSnapshot{}, err
		}
	}
	return item, snapshot, nil
}

func creditDriverWallet(
	ctx context.Context,
	transaction *ent.Tx,
	profile *ent.DriverProfile,
	amountCentavos int64,
) error {
	account, err := transaction.DriverWalletAccount.Query().
		Where(driverwalletaccount.DriverIDEQ(profile.UserID)).
		Only(ctx)
	if ent.IsNotFound(err) {
		account, err = transaction.DriverWalletAccount.Create().
			SetDriverID(profile.UserID).
			SetBalanceCentavos(profile.WalletBalanceCentavos).
			Save(ctx)
	}
	if err != nil {
		return err
	}
	if _, err := account.Update().
		AddBalanceCentavos(amountCentavos).
		AddVersion(1).
		Save(ctx); err != nil {
		return err
	}
	_, err = profile.Update().AddWalletBalanceCentavos(amountCentavos).Save(ctx)
	return err
}

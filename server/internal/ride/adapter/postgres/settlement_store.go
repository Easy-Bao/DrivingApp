package postgres

import (
	"context"
	"errors"
	"fmt"
	"time"

	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

var _ ports.CashSettlementStore = (*RideRepository)(nil)

func (repository *RideRepository) SettleCash(ctx context.Context, rideID, driverID int) (domain.Ride, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return domain.Ride{}, err
	}
	dbRideID, err := toPostgresRideID(rideID, "ride id")
	if err != nil {
		return domain.Ride{}, err
	}
	dbDriverID, err := toPostgresRideID(driverID, "driver id")
	if err != nil {
		return domain.Ride{}, err
	}

	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("begin cash settlement transaction: %w", err)
	}
	defer func() {
		_ = transaction.Rollback(ctx)
	}()

	transactionQueries := repository.queries.WithTx(transaction)
	rideItem, err := transactionQueries.LockCompletedRideForCashSettlement(
		ctx,
		databasepostgres.LockCompletedRideForCashSettlementParams{
			ID:       dbRideID,
			DriverID: pgtype.Int4{Int32: dbDriverID, Valid: true},
		},
	)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("find completed ride: %w", err)
	}
	settlementRecord, settlement, err := repository.ensureNativeRideSettlement(ctx, transactionQueries, rideItem)
	if err != nil {
		return domain.Ride{}, err
	}
	if settlementRecord.PaymentStatus == "paid" {
		if rideItem.PaymentStatus != "paid" {
			rideItem, err = transactionQueries.MarkRidePaidFromSettlement(ctx, databasepostgres.MarkRidePaidFromSettlementParams{
				CashReceivedAt:       settlementRecord.CashReceivedAt,
				CommissionBps:        settlementRecord.CommissionBps,
				CommissionCentavos:   settlementRecord.CommissionCentavos,
				DriverPayoutCentavos: settlementRecord.DriverPayoutCentavos,
				RideID:               rideItem.ID,
			})
			if err != nil {
				return domain.Ride{}, fmt.Errorf("synchronize paid ride: %w", err)
			}
		}
		if err := transaction.Commit(ctx); err != nil {
			return domain.Ride{}, fmt.Errorf("commit already-settled ride: %w", err)
		}
		return fromPostgresRide(rideItem)
	}

	profile, err := transactionQueries.GetDriverProfileByUserIDFull(ctx, dbDriverID)
	if err != nil {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	if settlement.DriverPayoutCentavos <= 0 {
		return domain.Ride{}, domain.ErrInvalidFareOffer
	}
	if err := transactionQueries.CreateWalletLedger(ctx, databasepostgres.CreateWalletLedgerParams{
		DriverID:           dbDriverID,
		RideID:             rideItem.ID,
		AmountCentavos:     settlement.DriverPayoutCentavos,
		CommissionCentavos: settlement.CommissionCentavos,
		Kind:               "cash_trip",
	}); err != nil {
		return domain.Ride{}, fmt.Errorf("create cash settlement ledger: %w", err)
	}
	if err := creditNativeDriverWallet(ctx, transactionQueries, profile, settlement.DriverPayoutCentavos); err != nil {
		return domain.Ride{}, fmt.Errorf("credit driver wallet: %w", err)
	}
	settledAt := pgtype.Timestamptz{Time: time.Now().UTC(), Valid: true}
	if _, err := transactionQueries.MarkRideSettlementPaid(ctx, databasepostgres.MarkRideSettlementPaidParams{
		CashReceivedAt:       settledAt,
		SettledAt:            settledAt,
		CommissionBps:        pgtype.Int8{Int64: settlement.CommissionBPS, Valid: true},
		CommissionCentavos:   settlement.CommissionCentavos,
		DriverPayoutCentavos: settlement.DriverPayoutCentavos,
		SettlementID:         settlementRecord.ID,
	}); err != nil {
		return domain.Ride{}, fmt.Errorf("mark ride settlement paid: %w", err)
	}
	rideItem, err = transactionQueries.MarkRidePaidFromSettlement(ctx, databasepostgres.MarkRidePaidFromSettlementParams{
		CashReceivedAt:       settledAt,
		CommissionBps:        pgtype.Int8{Int64: settlement.CommissionBPS, Valid: true},
		CommissionCentavos:   settlement.CommissionCentavos,
		DriverPayoutCentavos: settlement.DriverPayoutCentavos,
		RideID:               rideItem.ID,
	})
	if err != nil {
		return domain.Ride{}, fmt.Errorf("mark ride paid: %w", err)
	}
	if err := transaction.Commit(ctx); err != nil {
		return domain.Ride{}, fmt.Errorf("commit cash settlement transaction: %w", err)
	}
	return fromPostgresRide(rideItem)
}

func (repository *RideRepository) ensureNativeRideSettlement(
	ctx context.Context,
	queries *databasepostgres.Queries,
	rideItem databasepostgres.Ride,
) (databasepostgres.RideSettlement, domain.SettlementSnapshot, error) {
	settlementRecord, err := queries.GetRideSettlementByRideID(ctx, rideItem.ID)
	hasSettlement := true
	if errors.Is(err, pgx.ErrNoRows) {
		hasSettlement = false
	} else if err != nil {
		return databasepostgres.RideSettlement{}, domain.SettlementSnapshot{}, fmt.Errorf("find ride settlement: %w", err)
	}
	commissionBPS := repository.platformCommissionBPS
	if hasSettlement && settlementRecord.CommissionBps.Valid {
		commissionBPS = settlementRecord.CommissionBps.Int64
	} else if rideItem.CommissionBps.Valid {
		commissionBPS = rideItem.CommissionBps.Int64
	}
	settlement, err := domain.NewSettlementSnapshot(rideItem.FareCentavos, commissionBPS)
	if err != nil {
		return databasepostgres.RideSettlement{}, domain.SettlementSnapshot{}, err
	}
	if !hasSettlement {
		settlementRecord, err = queries.CreateRideSettlementForCash(ctx, databasepostgres.CreateRideSettlementForCashParams{
			RideID:               rideItem.ID,
			GrossFareCentavos:    settlement.FareCentavos,
			CommissionBps:        pgtype.Int8{Int64: settlement.CommissionBPS, Valid: true},
			CommissionCentavos:   settlement.CommissionCentavos,
			DriverPayoutCentavos: settlement.DriverPayoutCentavos,
			PaymentStatus:        rideItem.PaymentStatus,
			CashReceivedAt:       rideItem.CashReceivedAt,
			SettledAt:            rideItem.CashReceivedAt,
		})
		if err != nil {
			return databasepostgres.RideSettlement{}, domain.SettlementSnapshot{}, fmt.Errorf("create ride settlement: %w", err)
		}
		return settlementRecord, settlement, nil
	}
	if settlementRecord.GrossFareCentavos != settlement.FareCentavos {
		return databasepostgres.RideSettlement{}, domain.SettlementSnapshot{}, domain.ErrInvalidSettlement
	}
	if settlementRecord.CommissionBps.Valid &&
		(settlementRecord.CommissionCentavos != settlement.CommissionCentavos ||
			settlementRecord.DriverPayoutCentavos != settlement.DriverPayoutCentavos) {
		return databasepostgres.RideSettlement{}, domain.SettlementSnapshot{}, domain.ErrInvalidSettlement
	}
	if !settlementRecord.CommissionBps.Valid && settlementRecord.PaymentStatus != "paid" {
		settlementRecord, err = queries.UpdateRideSettlementEconomics(
			ctx,
			databasepostgres.UpdateRideSettlementEconomicsParams{
				CommissionBps:        pgtype.Int8{Int64: settlement.CommissionBPS, Valid: true},
				CommissionCentavos:   settlement.CommissionCentavos,
				DriverPayoutCentavos: settlement.DriverPayoutCentavos,
				SettlementID:         settlementRecord.ID,
			},
		)
		if err != nil {
			return databasepostgres.RideSettlement{},
				domain.SettlementSnapshot{},
				fmt.Errorf("repair ride settlement economics: %w", err)
		}
	}
	return settlementRecord, settlement, nil
}

func creditNativeDriverWallet(
	ctx context.Context,
	queries *databasepostgres.Queries,
	profile databasepostgres.DriverProfile,
	amountCentavos int64,
) error {
	account, err := queries.GetDriverWalletAccountForUpdate(ctx, profile.UserID)
	if errors.Is(err, pgx.ErrNoRows) {
		account, err = queries.CreateDriverWalletAccount(ctx, databasepostgres.CreateDriverWalletAccountParams{
			DriverID:        profile.UserID,
			BalanceCentavos: profile.WalletBalanceCentavos,
		})
	}
	if err != nil {
		return err
	}
	if _, err := queries.CreditDriverWalletAccount(ctx, databasepostgres.CreditDriverWalletAccountParams{
		ID:              account.ID,
		BalanceCentavos: amountCentavos,
	}); err != nil {
		return err
	}
	return queries.CreditDriverProfileWallet(ctx, databasepostgres.CreditDriverProfileWalletParams{
		UserID:                profile.UserID,
		WalletBalanceCentavos: amountCentavos,
	})
}

package postgres

import (
	"context"
	"errors"
	"fmt"
	"time"

	platformdatabase "github.com/Easy-Bao/DrivingApp/server/internal/platform/database"
	databasepostgres "github.com/Easy-Bao/DrivingApp/server/internal/platform/database/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

var _ ports.CashSettlementStore = (*RideRepository)(nil)

func (repository *RideRepository) SettleCash(
	ctx context.Context,
	request domain.CashSettlementRequest,
) (domain.Ride, error) {
	if err := repository.validateNativeReadRepository(); err != nil {
		return domain.Ride{}, err
	}
	dbRideID, err := toPostgresRideID(request.RideID, "ride id")
	if err != nil {
		return domain.Ride{}, err
	}
	dbDriverID, err := toPostgresRideID(request.DriverID, "driver id")
	if err != nil {
		return domain.Ride{}, err
	}

	transaction, err := repository.pool.Begin(ctx)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("begin cash settlement transaction: %w", err)
	}
	defer func() {
		platformdatabase.Rollback(ctx, transaction)
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
	if settlementRecord.CashOutcome != string(domain.CashOutcomeUnpaid) ||
		settlementRecord.CashReceivedAmount != 0 ||
		settlementRecord.CashChangeAmount != 0 {
		if !cashSettlementMatchesRecord(settlementRecord, request) {
			return domain.Ride{}, domain.ErrInvalidSettlement
		}
		if rideItem.PaymentStatus != settlementRecord.PaymentStatus ||
			rideItem.CashReceivedAmount != settlementRecord.CashReceivedAmount ||
			rideItem.CashChangeAmount != settlementRecord.CashChangeAmount ||
			rideItem.CashOutcome != settlementRecord.CashOutcome {
			rideItem, err = transactionQueries.MarkRideCashOutcome(ctx, databasepostgres.MarkRideCashOutcomeParams{
				PaymentStatus:      settlementRecord.PaymentStatus,
				CashReceivedAt:     settlementRecord.CashReceivedAt,
				CashReceivedAmount: settlementRecord.CashReceivedAmount,
				CashChangeAmount:   settlementRecord.CashChangeAmount,
				CashOutcome:        settlementRecord.CashOutcome,
				CommissionBps:      settlementRecord.CommissionBps,
				CommissionAmount:   settlementRecord.CommissionAmount,
				DriverPayoutAmount: settlementRecord.DriverPayoutAmount,
				RideID:             rideItem.ID,
			})
			if err != nil {
				return domain.Ride{}, fmt.Errorf("synchronize recorded cash outcome: %w", err)
			}
		}
		if err := transaction.Commit(ctx); err != nil {
			return domain.Ride{}, fmt.Errorf("commit already-recorded cash outcome: %w", err)
		}
		ride, err := fromPostgresRide(rideItem)
		if err != nil {
			return domain.Ride{}, fmt.Errorf("map already-recorded cash outcome: %w", err)
		}
		return ride, nil
	}

	validated, err := domain.NewCashSettlement(
		rideItem.FareAmount,
		request.ReceivedAmount,
		request.ChangeAmount,
		request.Outcome,
		settlement.CommissionBPS,
	)
	if err != nil {
		return domain.Ride{}, err
	}

	profile, err := transactionQueries.GetDriverProfileByUserIDFull(ctx, dbDriverID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return domain.Ride{}, domain.ErrUnauthorizedRide
		}
		return domain.Ride{}, fmt.Errorf("find settlement driver profile: %w", err)
	}
	if validated.Snapshot.DriverPayoutAmount > 0 {
		ledgerKind := "cash_trip"
		if validated.Outcome == domain.CashOutcomePartial {
			ledgerKind = "cash_trip_partial"
		}
		if err := transactionQueries.CreateWalletLedger(ctx, databasepostgres.CreateWalletLedgerParams{
			DriverID:         dbDriverID,
			RideID:           rideItem.ID,
			Amount:           validated.Snapshot.DriverPayoutAmount,
			CommissionAmount: validated.Snapshot.CommissionAmount,
			Kind:             ledgerKind,
		}); err != nil {
			return domain.Ride{}, fmt.Errorf("create cash settlement ledger: %w", err)
		}
		if err := creditNativeDriverWallet(ctx, transactionQueries, profile, validated.Snapshot.DriverPayoutAmount); err != nil {
			return domain.Ride{}, fmt.Errorf("credit driver wallet: %w", err)
		}
	}
	collectedAt := pgtype.Timestamptz{Time: time.Now().UTC(), Valid: true}
	settledAt := pgtype.Timestamptz{}
	if validated.PaymentStatus == "paid" {
		settledAt = collectedAt
	}
	if _, err := transactionQueries.MarkRideSettlementOutcome(ctx, databasepostgres.MarkRideSettlementOutcomeParams{
		PaymentStatus:      validated.PaymentStatus,
		CashReceivedAt:     collectedAt,
		CashReceivedAmount: validated.ReceivedAmount,
		CashChangeAmount:   validated.ChangeAmount,
		CashOutcome:        string(validated.Outcome),
		SettledAt:          settledAt,
		CommissionBps:      pgtype.Int4{Int32: int32(settlement.CommissionBPS), Valid: true},
		CommissionAmount:   validated.Snapshot.CommissionAmount,
		DriverPayoutAmount: validated.Snapshot.DriverPayoutAmount,
		SettlementID:       settlementRecord.ID,
	}); err != nil {
		return domain.Ride{}, fmt.Errorf("record cash settlement outcome: %w", err)
	}
	rideItem, err = transactionQueries.MarkRideCashOutcome(ctx, databasepostgres.MarkRideCashOutcomeParams{
		PaymentStatus:      validated.PaymentStatus,
		CashReceivedAt:     collectedAt,
		CashReceivedAmount: validated.ReceivedAmount,
		CashChangeAmount:   validated.ChangeAmount,
		CashOutcome:        string(validated.Outcome),
		CommissionBps:      pgtype.Int4{Int32: int32(settlement.CommissionBPS), Valid: true},
		CommissionAmount:   validated.Snapshot.CommissionAmount,
		DriverPayoutAmount: validated.Snapshot.DriverPayoutAmount,
		RideID:             rideItem.ID,
	})
	if err != nil {
		return domain.Ride{}, fmt.Errorf("mark ride cash outcome: %w", err)
	}
	if err := transaction.Commit(ctx); err != nil {
		return domain.Ride{}, fmt.Errorf("commit cash settlement transaction: %w", err)
	}
	ride, err := fromPostgresRide(rideItem)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("map settled ride: %w", err)
	}
	return ride, nil
}

func cashSettlementMatchesRecord(
	record databasepostgres.RideSettlement,
	request domain.CashSettlementRequest,
) bool {
	return record.CashOutcome == string(request.Outcome) &&
		record.CashReceivedAmount == request.ReceivedAmount &&
		record.CashChangeAmount == request.ChangeAmount
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
		commissionBPS = int64(settlementRecord.CommissionBps.Int32)
	} else if rideItem.CommissionBps.Valid {
		commissionBPS = int64(rideItem.CommissionBps.Int32)
	}
	settlement, err := domain.NewSettlementSnapshot(rideItem.FareAmount, commissionBPS)
	if err != nil {
		return databasepostgres.RideSettlement{}, domain.SettlementSnapshot{}, err
	}
	if !hasSettlement {
		settlementRecord, err = queries.CreateRideSettlementForCash(ctx, databasepostgres.CreateRideSettlementForCashParams{
			RideID:             rideItem.ID,
			GrossFare:          settlement.FareAmount,
			CommissionBps:      pgtype.Int4{Int32: int32(settlement.CommissionBPS), Valid: true},
			CommissionAmount:   settlement.CommissionAmount,
			DriverPayoutAmount: settlement.DriverPayoutAmount,
			PaymentStatus:      rideItem.PaymentStatus,
			CashReceivedAt:     rideItem.CashReceivedAt,
			CashReceivedAmount: rideItem.CashReceivedAmount,
			CashChangeAmount:   rideItem.CashChangeAmount,
			CashOutcome:        rideItem.CashOutcome,
			SettledAt:          rideItem.CashReceivedAt,
		})
		if err != nil {
			return databasepostgres.RideSettlement{}, domain.SettlementSnapshot{}, fmt.Errorf("create ride settlement: %w", err)
		}
		return settlementRecord, settlement, nil
	}
	if settlementRecord.GrossFare != settlement.FareAmount {
		return databasepostgres.RideSettlement{}, domain.SettlementSnapshot{}, domain.ErrInvalidSettlement
	}
	if !settlementRecord.CommissionBps.Valid && settlementRecord.PaymentStatus != "paid" {
		settlementRecord, err = queries.UpdateRideSettlementEconomics(
			ctx,
			databasepostgres.UpdateRideSettlementEconomicsParams{
				CommissionBps:      pgtype.Int4{Int32: int32(settlement.CommissionBPS), Valid: true},
				CommissionAmount:   settlement.CommissionAmount,
				DriverPayoutAmount: settlement.DriverPayoutAmount,
				SettlementID:       settlementRecord.ID,
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
	amount int64,
) error {
	account, err := queries.GetDriverWalletAccountForUpdate(ctx, profile.UserID)
	if errors.Is(err, pgx.ErrNoRows) {
		account, err = queries.CreateDriverWalletAccount(ctx, databasepostgres.CreateDriverWalletAccountParams{
			DriverID: profile.UserID,
			Balance:  0,
		})
	}
	if err != nil {
		return fmt.Errorf("load driver wallet account: %w", err)
	}
	if _, err := queries.CreditDriverWalletAccount(ctx, databasepostgres.CreditDriverWalletAccountParams{
		ID:      account.ID,
		Balance: amount,
	}); err != nil {
		return fmt.Errorf("credit driver wallet account: %w", err)
	}
	return nil
}

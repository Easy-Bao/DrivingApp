import { resetPaymentsLedgerForTesting } from '@/features/payments/composables/use-payments-ledger'
import { resetSettlementsForTesting } from '@/features/payments/composables/use-settlements'
import { resetTopupsForTesting } from '@/features/payments/composables/use-topups'

export type {
  AdjustmentClaimStatus,
  AdjustmentClaimType,
  CashOutcome,
  ChannelKind,
  CommissionTier,
  CompanyCollectionAccount,
  CreateCommissionTierInput,
  CreateCompanyAccountInput,
  CreateFareTierRuleInput,
  DriverEarningSummary,
  DriverWalletRow,
  DriverWalletStanding,
  FareAdjustmentClaim,
  FareTierRule,
  LedgerEntryType,
  PaymentMutationResult,
  RideSettlementRecord,
  SaveCommissionTierInput,
  SettlementResolutionState,
  TopUpPaymentMethod,
  TopUpRequest,
  TopUpStatus,
  UpdateCompanyAccountInput,
  WalletLedgerEntry,
} from '@/features/payments/types'

export { buildQrSvg, buildReceiptPreviewSvg } from '@/features/payments/domain/svg-receipt'

export {
  computeDriverTakeHomeCentavos,
  computePlatformCommissionCentavos,
  getPlatformFeeCentavos,
  getShortfallCentavos,
} from '@/features/payments/domain/calculations'

export {
  MAX_QR_FILE_BYTES,
  validateCommissionTierInput,
  validateCompanyAccountInput,
  validateFareRuleInput,
  validateMerchantReference,
  validateQrUploadFile,
  validateWalletAdjustment,
} from '@/features/payments/domain/validation'

export { useTopups } from '@/features/payments/composables/use-topups'
export { useSettlements } from '@/features/payments/composables/use-settlements'
export {
  useCollectionAccounts,
  useCommissionTiers,
  useDriverEarnings,
  useFarePricing,
  useRefundClaims,
  useWalletAccounts,
  useWalletTransactions,
} from '@/features/payments/composables/use-payments-ledger'

export function resetPaymentsForTesting() {
  resetTopupsForTesting()
  resetSettlementsForTesting()
  resetPaymentsLedgerForTesting()
}

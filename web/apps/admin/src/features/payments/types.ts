export type TopUpPaymentMethod = 'Company QR Code' | 'Company Bank Transfer'
export type TopUpStatus = 'Pending' | 'Verified' | 'Rejected'

export interface TopUpRequest {
  id: string
  driverName: string
  driverPhone: string
  vehiclePlate: string
  bodyUnit: string
  currentBalanceCentavos: number
  amountCentavos: number
  paymentMethod: TopUpPaymentMethod
  channelProvider: string
  senderAccount: string
  referenceCode: string
  submittedAt: string
  transactionTimestamp: string
  companyAccountPaid: string
  proofNote: string
  receiptFileName: string
  receiptPreviewUrl: string
  rejectionReason?: string
  status: TopUpStatus
}

export type CashOutcome = 'paid' | 'partial' | 'refused' | 'unpaid' | 'disputed'
export type SettlementResolutionState = 'reconciled' | 'pending_review' | 'waived'

export interface RideSettlementRecord {
  id: string
  rideId: string
  driverId: string
  driverName: string
  driverPhone: string
  plateNumber: string
  passengerName: string
  passengerPhone: string
  routeSummary: string
  grossFareCentavos: number
  commissionBps: number
  tipCentavos: number
  cashReceivedCentavos: number
  cashChangeCentavos: number
  cashOutcome: CashOutcome
  resolutionState: SettlementResolutionState
  reportedAt: string
  notes: string
  resolutionNotes: string
  resolvedAt?: string
}

export interface CommissionTier {
  id: string
  category: string
  rateBps: number
  fixedBookingFeeCentavos: number
  minWalletBalanceCentavos: number
  eligibilityRule: string
  settlementNote: string
}

export interface SaveCommissionTierInput {
  rateBps: number
  fixedBookingFeeCentavos: number
  minWalletBalanceCentavos: number
  eligibilityRule: string
}

export interface FareTierRule {
  id: string
  tier: string
  corridorScope: string
  baseFareCentavos: number
  perKmCentavos: number
  perMinuteCentavos: number
  minimumFareCentavos: number
  cancellationFeeCentavos: number
  maxBiddingSurgeCap: number
  highRatingDriverBonus: number
}

export type DriverWalletStanding = 'Prepaid Credit Active' | 'Low Prepaid Wallet'

export interface DriverEarningSummary {
  id: string
  driver: string
  plateNumber: string
  trips: number
  cashGrossCentavos: number
  commissionBps: number
  walletStatus: DriverWalletStanding
}

export type LedgerEntryType =
  | 'Commission Deduction'
  | 'QRPh Wallet Top-Up'
  | 'Bank Top-Up'
  | 'Settlement Fee Waiver'
  | 'Operator Wallet Adjustment'

export interface WalletLedgerEntry {
  id: string
  referenceId: string
  driver: string
  type: LedgerEntryType
  method: string
  amountCentavos: number
  direction: 'credit' | 'debit'
  status: 'Settled' | 'Pending Review'
  timestamp: string
}

export interface DriverWalletRow {
  driverId: string
  driver: string
  phone: string
  plateNumber: string
  balanceCentavos: number
  totalTopupsCentavos: number
  totalCommissionPaidCentavos: number
  lastTopupAt: string
}

export type ChannelKind = 'QRPh Wallet' | 'Corporate Bank'

export interface CompanyCollectionAccount {
  id: string
  label: string
  channelType: ChannelKind
  institution: string
  accountNumber: string
  accountHolder: string
  branchOrMerchantId: string
  qrPreviewUrl: string
  qrUpdatedAt: string
  isActive: boolean
}

export interface CreateCompanyAccountInput {
  label: string
  channelType: ChannelKind
  institution: string
  accountNumber: string
  accountHolder: string
  branchOrMerchantId: string
}

export interface UpdateCompanyAccountInput {
  label: string
  institution: string
  accountNumber: string
  accountHolder: string
  branchOrMerchantId: string
}

export type AdjustmentClaimType = 'Passenger Cash Rebate' | 'Driver Commission Waiver'
export type AdjustmentClaimStatus = 'Pending Approval' | 'Approved & Credited' | 'Declined'

export interface FareAdjustmentClaim {
  id: string
  tripId: string
  claimant: string
  claimType: AdjustmentClaimType
  amountCentavos: number
  reason: string
  status: AdjustmentClaimStatus
  resolutionNote?: string
}

export type PaymentMutationResult = { ok: true; message?: string } | { ok: false; error: string }

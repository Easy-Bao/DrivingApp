import type {
  AppSystemConfig,
  CompliancePolicyConfig,
  DispatchPolicyConfig,
  PlatformConfig,
  PricingPolicyConfig,
  SafetyPolicyConfig,
  WalletPolicyConfig,
} from '@/features/settings/types'

export const DEFAULT_PLATFORM_CONFIG: PlatformConfig = {
  biddingWindowSeconds: 90,
  gpsBeaconIntervalSeconds: 5,
  maxBiddingSurgeCap: 2.5,
  ratingBonusThreshold: 4.5,
  ratingBonusMultiplier: 1.05,
  minWalletBalanceCentavos: 5000,
  cancellationFeeCentavos: 1500,
  baseFareCentavos: 2500,
  enforceDocumentGate: true,
  enableSurgePricing: true,
  autoLockLowBalanceDispatch: true,
}

export const DEFAULT_PRICING_POLICY: PricingPolicyConfig = {
  baseFareCentavos: DEFAULT_PLATFORM_CONFIG.baseFareCentavos,
  cancellationFeeCentavos: DEFAULT_PLATFORM_CONFIG.cancellationFeeCentavos,
  cancellationGraceMinutes: 3,
  maxBiddingSurgeCap: DEFAULT_PLATFORM_CONFIG.maxBiddingSurgeCap,
  enableSurgePricing: DEFAULT_PLATFORM_CONFIG.enableSurgePricing,
  ratingBonusThreshold: DEFAULT_PLATFORM_CONFIG.ratingBonusThreshold,
  ratingBonusMultiplier: DEFAULT_PLATFORM_CONFIG.ratingBonusMultiplier,
  lowRatingSurgePenaltyMultiplier: 1.0,
  enableNightDifferential: false,
  nightDifferentialPercent: 15,
  nightStartHour: 22,
  nightEndHour: 5,
}

export const DEFAULT_WALLET_POLICY: WalletPolicyConfig = {
  minWalletBalanceCentavos: DEFAULT_PLATFORM_CONFIG.minWalletBalanceCentavos,
  lowBalanceWarningCentavos: 10000,
  minTopUpAmountCentavos: 5000,
  maxTopUpAmountCentavos: 1000000,
  autoLockLowBalanceDispatch: DEFAULT_PLATFORM_CONFIG.autoLockLowBalanceDispatch,
  requireReceiptProof: true,
  topUpVerificationSlaMinutes: 30,
}

export const DEFAULT_DISPATCH_POLICY: DispatchPolicyConfig = {
  biddingWindowSeconds: DEFAULT_PLATFORM_CONFIG.biddingWindowSeconds,
  dispatchSearchRadiusKm: 5,
  maxOffersPerSession: 8,
  minPassengerBidPercent: 80,
  maxPassengerBidPercent: 180,
  gpsBeaconIntervalSeconds: DEFAULT_PLATFORM_CONFIG.gpsBeaconIntervalSeconds,
  driverLocationMaxAgeSeconds: 45,
  passengerNoShowWaitMinutes: 5,
  arrivalRadiusMeters: 250,
  completionRadiusMeters: 250,
  allowManualDispatchOverride: true,
}

export const DEFAULT_COMPLIANCE_POLICY: CompliancePolicyConfig = {
  enforceDocumentGate: DEFAULT_PLATFORM_CONFIG.enforceDocumentGate,
  expiryWarningLeadDays: 30,
  criticalExpiryDays: 7,
  expiryGracePeriodDays: 0,
  autoSuspendOnExpiry: true,
}

export const DEFAULT_SAFETY_POLICY: SafetyPolicyConfig = {
  sosAutoEscalateSeconds: 60,
  sosLocationPingSeconds: 3,
  autoNotifyRespondersOnCritical: true,
  requireResolutionNote: true,
  autoSuspendOnCriticalReport: false,
}

export const DEFAULT_APP_SYSTEM_CONFIG: AppSystemConfig = {
  reportingTimezone: 'Asia/Manila',
  supportEmail: 'support@easyride.ph',
  supportPhone: '+63 62 925 7016',
  passengerMinVersion: '1.4.0',
  driverMinVersion: '1.4.0',
  enforceMinAppVersion: true,
  maintenanceMode: false,
  maintenanceNotice:
    'Scheduled dispatch maintenance in progress. Active trips continue without interruption.',
}

export function clonePlatformConfig(config: PlatformConfig): PlatformConfig {
  return { ...config }
}

import type { PlatformConfig } from '@/features/settings/types'

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

export function clonePlatformConfig(config: PlatformConfig): PlatformConfig {
  return { ...config }
}

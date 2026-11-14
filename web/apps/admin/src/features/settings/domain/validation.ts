import type {
  PlatformConfig,
  SaveLegalDocumentInput,
  SaveMunicipalityInput,
  SaveServiceZoneInput,
} from '@/features/settings/types'

function isFiniteInRange(value: number, min: number, max: number): boolean {
  return Number.isFinite(value) && value >= min && value <= max
}

export function validatePlatformConfig(config: PlatformConfig): string | null {
  if (!isFiniteInRange(config.biddingWindowSeconds, 30, 300)) {
    return 'Bidding window duration must be between 30 and 300 seconds.'
  }
  if (!isFiniteInRange(config.gpsBeaconIntervalSeconds, 2, 60)) {
    return 'Driver GPS ping interval must be between 2 and 60 seconds.'
  }
  if (!isFiniteInRange(config.maxBiddingSurgeCap, 1, 2.5)) {
    return 'Maximum surge ceiling must remain between 1.0x and 2.5x.'
  }
  if (!isFiniteInRange(config.ratingBonusThreshold, 1, 5)) {
    return 'Rating bonus threshold must be between 1.0 and 5.0 stars.'
  }
  if (!isFiniteInRange(config.ratingBonusMultiplier, 1, 1.2)) {
    return 'Rating bonus multiplier must be between 1.0x and 1.2x.'
  }
  if (!Number.isFinite(config.minWalletBalanceCentavos) || config.minWalletBalanceCentavos < 0) {
    return 'Minimum prepaid balance must be PHP 0.00 or higher.'
  }
  if (!Number.isFinite(config.cancellationFeeCentavos) || config.cancellationFeeCentavos < 0) {
    return 'Standard cancellation fee must be PHP 0.00 or higher.'
  }
  if (!Number.isFinite(config.baseFareCentavos) || config.baseFareCentavos < 0) {
    return 'Baseline flagdown fare must be PHP 0.00 or higher.'
  }
  return null
}

export function validateServiceZoneInput(
  input: SaveServiceZoneInput,
  maxSurgeCap = 2.5,
): string | null {
  if (!input.name.trim() || !input.barangaysCovered.trim()) {
    return 'Provide zone title and covered Pagadian barangays.'
  }
  const ceiling = Number.isFinite(maxSurgeCap) ? Math.max(1, maxSurgeCap) : 2.5
  if (!isFiniteInRange(input.surgeFactor, 1, ceiling)) {
    return `Zone surge multiplier must remain between 1.0x and ${ceiling.toFixed(1)}x.`
  }
  if (!Number.isFinite(input.polygonPoints) || input.polygonPoints < 4) {
    return 'Geofence zone polygon requires at least 4 coordinate vertices.'
  }
  return null
}

export function validateMunicipalityInput(input: SaveMunicipalityInput): string | null {
  if (!input.municipality.trim() || !input.zipCode.trim()) {
    return 'Enter municipality name and Philippine postal code.'
  }
  if (!/^\d{4}$/.test(input.zipCode.trim())) {
    return 'Philippine postal code must be a 4-digit numeric ZIP code.'
  }
  if (!Number.isFinite(input.minFareCentavos) || input.minFareCentavos < 1500) {
    return 'Minimum flagdown base fare must be ₱15.00 or higher.'
  }
  return null
}

export function validateLegalDocumentInput(input: SaveLegalDocumentInput): string | null {
  if (!input.title.trim() || !input.markdownBody.trim()) {
    return 'Document heading and policy content are required.'
  }
  return null
}

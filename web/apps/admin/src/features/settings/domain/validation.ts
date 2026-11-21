import type {
  AppSystemConfig,
  CompliancePolicyConfig,
  DispatchPolicyConfig,
  PlatformConfig,
  PricingPolicyConfig,
  SafetyPolicyConfig,
  SaveDocumentRequirementInput,
  SaveEmergencyHotlineInput,
  SaveFareDiscountInput,
  SaveLegalDocumentInput,
  SaveMunicipalityInput,
  SaveServiceZoneInput,
  SaveVehicleClassInput,
  WalletPolicyConfig,
} from '@/features/settings/types'

function isFiniteInRange(value: number, min: number, max: number): boolean {
  return Number.isFinite(value) && value >= min && value <= max
}

const SEMVER_PATTERN = /^\d+\.\d+\.\d+$/

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

export function validatePricingPolicy(policy: PricingPolicyConfig): string | null {
  if (!Number.isFinite(policy.baseFareCentavos) || policy.baseFareCentavos <= 0) {
    return 'Baseline flagdown fare must be greater than PHP 0.00.'
  }
  if (!Number.isFinite(policy.cancellationFeeCentavos) || policy.cancellationFeeCentavos < 0) {
    return 'Standard cancellation fee must be PHP 0.00 or higher.'
  }
  if (!isFiniteInRange(policy.cancellationGraceMinutes, 0, 15)) {
    return 'Cancellation grace window must be between 0 and 15 minutes.'
  }
  if (!isFiniteInRange(policy.maxBiddingSurgeCap, 1, 2.5)) {
    return 'Maximum surge ceiling must remain between 1.0x and 2.5x.'
  }
  if (!isFiniteInRange(policy.ratingBonusThreshold, 1, 5)) {
    return 'Rating bonus threshold must be between 1.0 and 5.0 stars.'
  }
  if (!isFiniteInRange(policy.ratingBonusMultiplier, 1, 1.2)) {
    return 'High-rating bonus multiplier must be between 1.0x and 1.2x.'
  }
  if (!isFiniteInRange(policy.lowRatingSurgePenaltyMultiplier, 0.5, 1.0)) {
    return 'Low-rating surge penalty multiplier must remain between 0.5x and 1.0x.'
  }
  if (!isFiniteInRange(policy.nightDifferentialPercent, 0, 50)) {
    return 'Night differential surcharge must remain between 0% and 50%.'
  }
  if (
    !isFiniteInRange(policy.nightStartHour, 0, 23) ||
    !isFiniteInRange(policy.nightEndHour, 0, 23)
  ) {
    return 'Night differential hours must use valid 24-hour clock values (0–23).'
  }
  return null
}

export function validateFareDiscountInput(input: SaveFareDiscountInput): string | null {
  if (!input.name.trim() || !input.legalReference.trim()) {
    return 'Provide a discount rule name and statutory or policy reference.'
  }
  if (!isFiniteInRange(input.discountPercent, 1, 50)) {
    return 'Discount percentage must be between 1% and 50%.'
  }
  return null
}

export function validateWalletPolicy(policy: WalletPolicyConfig): string | null {
  if (!Number.isFinite(policy.minWalletBalanceCentavos) || policy.minWalletBalanceCentavos < 0) {
    return 'Minimum dispatch wallet balance must be PHP 0.00 or higher.'
  }
  if (
    !Number.isFinite(policy.lowBalanceWarningCentavos) ||
    policy.lowBalanceWarningCentavos < policy.minWalletBalanceCentavos
  ) {
    return 'Low-balance warning threshold must be greater than or equal to the minimum dispatch balance.'
  }
  if (!Number.isFinite(policy.minTopUpAmountCentavos) || policy.minTopUpAmountCentavos < 1000) {
    return 'Minimum top-up increment must be PHP 10.00 or higher.'
  }
  if (
    !Number.isFinite(policy.maxTopUpAmountCentavos) ||
    policy.maxTopUpAmountCentavos < policy.minTopUpAmountCentavos
  ) {
    return 'Maximum single top-up must be greater than or equal to the minimum top-up increment.'
  }
  if (!isFiniteInRange(policy.topUpVerificationSlaMinutes, 5, 240)) {
    return 'Top-up verification SLA must remain between 5 and 240 minutes.'
  }
  return null
}

export function validateDispatchPolicy(policy: DispatchPolicyConfig): string | null {
  if (!isFiniteInRange(policy.biddingWindowSeconds, 30, 300)) {
    return 'Bidding window duration must be between 30 and 300 seconds.'
  }
  if (!isFiniteInRange(policy.dispatchSearchRadiusKm, 1, 25)) {
    return 'Driver spatial search radius must be between 1 and 25 km.'
  }
  if (!isFiniteInRange(policy.maxOffersPerSession, 1, 20)) {
    return 'Maximum driver offers per session must be between 1 and 20.'
  }
  if (!isFiniteInRange(policy.minPassengerBidPercent, 50, 100)) {
    return 'Passenger bid floor must remain between 50% and 100% of estimate.'
  }
  if (
    !isFiniteInRange(policy.maxPassengerBidPercent, 100, 250) ||
    policy.maxPassengerBidPercent < policy.minPassengerBidPercent
  ) {
    return 'Passenger bid ceiling must be between 100% and 250% and above the floor.'
  }
  if (!isFiniteInRange(policy.gpsBeaconIntervalSeconds, 2, 60)) {
    return 'Driver GPS ping interval must be between 2 and 60 seconds.'
  }
  if (
    !isFiniteInRange(policy.driverLocationMaxAgeSeconds, 15, 300) ||
    policy.driverLocationMaxAgeSeconds <= policy.gpsBeaconIntervalSeconds
  ) {
    return 'Stale GPS expiry must be between 15 and 300 seconds and exceed the beacon interval.'
  }
  if (!isFiniteInRange(policy.passengerNoShowWaitMinutes, 1, 30)) {
    return 'Passenger no-show grace wait must be between 1 and 30 minutes.'
  }
  if (!isFiniteInRange(policy.arrivalRadiusMeters, 50, 1000)) {
    return 'Arrival geofence radius must be between 50 and 1000 meters.'
  }
  if (!isFiniteInRange(policy.completionRadiusMeters, 50, 1000)) {
    return 'Completion geofence radius must be between 50 and 1000 meters.'
  }
  return null
}

export function validateVehicleClassInput(input: SaveVehicleClassInput): string | null {
  if (!input.name.trim() || !input.code.trim() || !input.description.trim()) {
    return 'Provide vehicle class name, unique code, and operational description.'
  }
  if (!isFiniteInRange(input.passengerCapacity, 1, 12)) {
    return 'Passenger capacity must be between 1 and 12 seats.'
  }
  if (!input.fareRuleId.trim() || !input.commissionTierId.trim()) {
    return 'Assign both a fare tariff rule and a commission tier.'
  }
  return null
}

export function validateCompliancePolicy(policy: CompliancePolicyConfig): string | null {
  if (!isFiniteInRange(policy.expiryWarningLeadDays, 7, 90)) {
    return 'Expiry warning lead time must be between 7 and 90 days.'
  }
  if (
    !isFiniteInRange(policy.criticalExpiryDays, 1, 30) ||
    policy.criticalExpiryDays >= policy.expiryWarningLeadDays
  ) {
    return 'Critical expiry escalation must be between 1 and 30 days and shorter than warning lead time.'
  }
  if (!isFiniteInRange(policy.expiryGracePeriodDays, 0, 14)) {
    return 'Post-expiry grace period must be between 0 and 14 days.'
  }
  return null
}

export function validateDocumentRequirementInput(
  input: SaveDocumentRequirementInput,
): string | null {
  if (!input.name.trim() || !input.issuingAuthority.trim()) {
    return 'Provide document requirement name and issuing authority.'
  }
  return null
}

export function validateSafetyPolicy(policy: SafetyPolicyConfig): string | null {
  if (!isFiniteInRange(policy.sosAutoEscalateSeconds, 15, 300)) {
    return 'SOS auto-escalation timer must be between 15 and 300 seconds.'
  }
  if (!isFiniteInRange(policy.sosLocationPingSeconds, 2, 30)) {
    return 'SOS emergency GPS ping interval must be between 2 and 30 seconds.'
  }
  return null
}

export function validateEmergencyHotlineInput(input: SaveEmergencyHotlineInput): string | null {
  if (
    !input.label.trim() ||
    !input.agency.trim() ||
    !input.phone.trim() ||
    !input.coverageArea.trim()
  ) {
    return 'Provide hotline label, agency, phone number, and coverage area.'
  }
  return null
}

export function validateAppSystemConfig(config: AppSystemConfig): string | null {
  if (!config.reportingTimezone.trim()) {
    return 'Select a reporting timezone.'
  }
  if (!config.supportEmail.trim() || !config.supportEmail.includes('@')) {
    return 'Enter a valid support contact email address.'
  }
  if (!config.supportPhone.trim()) {
    return 'Enter a support contact phone number.'
  }
  if (
    !SEMVER_PATTERN.test(config.passengerMinVersion.trim()) ||
    !SEMVER_PATTERN.test(config.driverMinVersion.trim())
  ) {
    return 'App minimum versions must follow semantic versioning (e.g., 1.4.0).'
  }
  if (config.maintenanceMode && !config.maintenanceNotice.trim()) {
    return 'Provide a maintenance notice banner when maintenance mode is enabled.'
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

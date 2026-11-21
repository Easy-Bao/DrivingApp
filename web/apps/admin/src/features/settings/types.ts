export type AuditSeverity = 'Critical' | 'Warning' | 'Info'

export type MunicipalityStatus = 'Active Launch Market' | 'Pilot Rollout' | 'Planned Expansion'

export type ServiceZoneStatus = 'Active' | 'Monitoring' | 'Paused'

export type LegalDocumentAudience = 'Passenger & Driver' | 'Driver Fleet' | 'All Platform Users'

export interface PlatformConfig {
  biddingWindowSeconds: number
  gpsBeaconIntervalSeconds: number
  maxBiddingSurgeCap: number
  ratingBonusThreshold: number
  ratingBonusMultiplier: number
  minWalletBalanceCentavos: number
  cancellationFeeCentavos: number
  baseFareCentavos: number
  enforceDocumentGate: boolean
  enableSurgePricing: boolean
  autoLockLowBalanceDispatch: boolean
}

export interface PricingPolicyConfig {
  baseFareCentavos: number
  cancellationFeeCentavos: number
  cancellationGraceMinutes: number
  maxBiddingSurgeCap: number
  enableSurgePricing: boolean
  ratingBonusThreshold: number
  ratingBonusMultiplier: number
  lowRatingSurgePenaltyMultiplier: number
  enableNightDifferential: boolean
  nightDifferentialPercent: number
  nightStartHour: number
  nightEndHour: number
}

export type DiscountEligibilityType = 'Senior Citizen' | 'PWD' | 'Student' | 'Promotional'

export interface FareDiscountRule {
  id: string
  name: string
  eligibilityType: DiscountEligibilityType
  discountPercent: number
  requiresVerificationId: boolean
  legalReference: string
  isActive: boolean
}

export interface SaveFareDiscountInput {
  name: string
  eligibilityType: DiscountEligibilityType
  discountPercent: number
  requiresVerificationId: boolean
  legalReference: string
}

export interface WalletPolicyConfig {
  minWalletBalanceCentavos: number
  lowBalanceWarningCentavos: number
  minTopUpAmountCentavos: number
  maxTopUpAmountCentavos: number
  autoLockLowBalanceDispatch: boolean
  requireReceiptProof: boolean
  topUpVerificationSlaMinutes: number
}

export interface DispatchPolicyConfig {
  biddingWindowSeconds: number
  dispatchSearchRadiusKm: number
  maxOffersPerSession: number
  minPassengerBidPercent: number
  maxPassengerBidPercent: number
  gpsBeaconIntervalSeconds: number
  driverLocationMaxAgeSeconds: number
  passengerNoShowWaitMinutes: number
  arrivalRadiusMeters: number
  completionRadiusMeters: number
  allowManualDispatchOverride: boolean
}

export interface VehicleClassConfig {
  id: string
  name: string
  code: string
  description: string
  passengerCapacity: number
  fareRuleId: string
  commissionTierId: string
  isElectric: boolean
  isActive: boolean
}

export interface SaveVehicleClassInput {
  name: string
  code: string
  description: string
  passengerCapacity: number
  fareRuleId: string
  commissionTierId: string
  isElectric: boolean
}

export interface CompliancePolicyConfig {
  enforceDocumentGate: boolean
  expiryWarningLeadDays: number
  criticalExpiryDays: number
  expiryGracePeriodDays: number
  autoSuspendOnExpiry: boolean
}

export type DocumentScope = 'Driver' | 'Vehicle' | 'Franchise'

export interface DocumentRequirementRule {
  id: string
  name: string
  scope: DocumentScope
  issuingAuthority: string
  mandatory: boolean
  requiresTwoSides: boolean
  tracksExpiry: boolean
  isActive: boolean
}

export interface SaveDocumentRequirementInput {
  name: string
  scope: DocumentScope
  issuingAuthority: string
  mandatory: boolean
  requiresTwoSides: boolean
  tracksExpiry: boolean
}

export interface SafetyPolicyConfig {
  sosAutoEscalateSeconds: number
  sosLocationPingSeconds: number
  autoNotifyRespondersOnCritical: boolean
  requireResolutionNote: boolean
  autoSuspendOnCriticalReport: boolean
}

export interface EmergencyHotline {
  id: string
  label: string
  agency: string
  phone: string
  coverageArea: string
  isPrimary: boolean
  isActive: boolean
}

export interface SaveEmergencyHotlineInput {
  label: string
  agency: string
  phone: string
  coverageArea: string
  isPrimary: boolean
}

export interface AppSystemConfig {
  reportingTimezone: string
  supportEmail: string
  supportPhone: string
  passengerMinVersion: string
  driverMinVersion: string
  enforceMinAppVersion: boolean
  maintenanceMode: boolean
  maintenanceNotice: string
}

export interface AuditLogEntry {
  id: string
  actor: string
  role: string
  action: string
  targetEntity: string
  ipAddress: string
  severity: AuditSeverity
  timestamp: string
  payloadDiff: string
}

export interface AppendAuditLogInput {
  action: string
  targetEntity: string
  severity: AuditSeverity
  payload: Record<string, unknown>
}

export interface MunicipalityMarket {
  id: string
  municipality: string
  province: string
  zipCode: string
  centerCoords: string
  minFareCentavos: number
  requireTodaMtop: boolean
  status: MunicipalityStatus
}

export interface SaveMunicipalityInput {
  municipality: string
  zipCode: string
  minFareCentavos: number
  requireTodaMtop: boolean
  status: MunicipalityStatus
}

export interface ServiceZone {
  id: string
  name: string
  barangaysCovered: string
  centerCoords: string
  surgeFactor: number
  polygonPoints: number
  activeDrivers: number
  status: ServiceZoneStatus
}

export interface SaveServiceZoneInput {
  name: string
  barangaysCovered: string
  centerCoords: string
  surgeFactor: number
  polygonPoints: number
  status: ServiceZoneStatus
}

export interface LegalDocument {
  id: string
  title: string
  audience: LegalDocumentAudience
  versionMajor: number
  versionMinor: number
  lastUpdated: string
  markdownBody: string
}

export interface SaveLegalDocumentInput {
  title: string
  markdownBody: string
  bumpMinor: boolean
}

export type MutationResult = { ok: true; message?: string } | { ok: false; error: string }

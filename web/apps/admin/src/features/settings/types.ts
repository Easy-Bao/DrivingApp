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

export type MutationResult = { ok: true } | { ok: false; error: string }

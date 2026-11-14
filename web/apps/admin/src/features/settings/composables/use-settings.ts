import { ref } from 'vue'
import { ROLE_PROFILES, getAuthSession } from '@/core'
import {
  INITIAL_AUDIT_LOGS,
  INITIAL_CITIES,
  INITIAL_LEGAL_DOCUMENTS,
  INITIAL_SERVICE_ZONES,
} from '@/features/settings/data/settings.seed'
import {
  DEFAULT_PLATFORM_CONFIG,
  clonePlatformConfig,
} from '@/features/settings/domain/platform-config'
import {
  validateLegalDocumentInput,
  validateMunicipalityInput,
  validatePlatformConfig,
  validateServiceZoneInput,
} from '@/features/settings/domain/validation'
import type {
  AppendAuditLogInput,
  AuditLogEntry,
  LegalDocument,
  MunicipalityMarket,
  MutationResult,
  PlatformConfig,
  SaveLegalDocumentInput,
  SaveMunicipalityInput,
  SaveServiceZoneInput,
  ServiceZone,
} from '@/features/settings/types'

const platformConfig = ref<PlatformConfig>(clonePlatformConfig(DEFAULT_PLATFORM_CONFIG))
const auditLogs = ref<AuditLogEntry[]>(structuredClone([...INITIAL_AUDIT_LOGS]))
const cities = ref<MunicipalityMarket[]>(structuredClone([...INITIAL_CITIES]))
const serviceZones = ref<ServiceZone[]>(structuredClone([...INITIAL_SERVICE_ZONES]))
const legalDocuments = ref<LegalDocument[]>(structuredClone([...INITIAL_LEGAL_DOCUMENTS]))

let auditSequence = 8905

function resolveActiveOperator(): { actor: string; role: string } {
  const session = getAuthSession()
  const roleLabel = session.role
    ? ROLE_PROFILES[session.role].label
    : ROLE_PROFILES.root_operator.label
  return {
    actor: session.operatorName || ROLE_PROFILES.root_operator.operatorName,
    role: roleLabel,
  }
}

function appendAuditEntry(input: AppendAuditLogInput): AuditLogEntry {
  const { actor, role } = resolveActiveOperator()
  const entry: AuditLogEntry = {
    id: `AUD-7016-${auditSequence++}`,
    actor,
    role,
    action: input.action,
    targetEntity: input.targetEntity,
    ipAddress: '103.164.28.41 (Pagadian Ops)',
    severity: input.severity,
    timestamp: 'Just Now · PHT',
    payloadDiff: JSON.stringify(input.payload),
  }
  auditLogs.value.unshift(entry)
  return entry
}

export function resetSettingsForTesting(): void {
  platformConfig.value = clonePlatformConfig(DEFAULT_PLATFORM_CONFIG)
  auditLogs.value = structuredClone([...INITIAL_AUDIT_LOGS])
  cities.value = structuredClone([...INITIAL_CITIES])
  serviceZones.value = structuredClone([...INITIAL_SERVICE_ZONES])
  legalDocuments.value = structuredClone([...INITIAL_LEGAL_DOCUMENTS])
  auditSequence = 8905
}

export function useAuditLogs() {
  return {
    logs: auditLogs,
    appendAuditLog: appendAuditEntry,
  }
}

export function usePlatformConfig() {
  function commitConfig(nextConfig: PlatformConfig, auditReason: string): MutationResult {
    const trimmedReason = auditReason.trim()
    if (!trimmedReason) {
      return { ok: false, error: 'Provide an operational reason before saving configuration.' }
    }
    const validationError = validatePlatformConfig(nextConfig)
    if (validationError) {
      return { ok: false, error: validationError }
    }
    const normalized: PlatformConfig = {
      biddingWindowSeconds: Math.round(nextConfig.biddingWindowSeconds),
      gpsBeaconIntervalSeconds: Math.round(nextConfig.gpsBeaconIntervalSeconds),
      maxBiddingSurgeCap: Number(nextConfig.maxBiddingSurgeCap.toFixed(2)),
      ratingBonusThreshold: Number(nextConfig.ratingBonusThreshold.toFixed(1)),
      ratingBonusMultiplier: Number(nextConfig.ratingBonusMultiplier.toFixed(2)),
      minWalletBalanceCentavos: Math.round(nextConfig.minWalletBalanceCentavos),
      cancellationFeeCentavos: Math.round(nextConfig.cancellationFeeCentavos),
      baseFareCentavos: Math.round(nextConfig.baseFareCentavos),
      enforceDocumentGate: Boolean(nextConfig.enforceDocumentGate),
      enableSurgePricing: Boolean(nextConfig.enableSurgePricing),
      autoLockLowBalanceDispatch: Boolean(nextConfig.autoLockLowBalanceDispatch),
    }
    platformConfig.value = normalized
    appendAuditEntry({
      action: 'RUNTIME_CONFIG_UPDATED',
      targetEntity: 'Platform Preferences · Pagadian City',
      severity: 'Warning',
      payload: {
        reason: trimmedReason,
        minWalletBalanceCentavos: normalized.minWalletBalanceCentavos,
        maxBiddingSurgeCap: normalized.maxBiddingSurgeCap,
        ratingBonusThreshold: normalized.ratingBonusThreshold,
        ratingBonusMultiplier: normalized.ratingBonusMultiplier,
      },
    })
    return { ok: true }
  }

  function resetToDefaults(): void {
    platformConfig.value = clonePlatformConfig(DEFAULT_PLATFORM_CONFIG)
  }

  return {
    config: platformConfig,
    commitConfig,
    resetToDefaults,
  }
}

export function useCities() {
  function saveMunicipality(
    editingMarketId: string | null,
    input: SaveMunicipalityInput,
  ): MutationResult & { message?: string } {
    const error = validateMunicipalityInput(input)
    if (error) {
      return { ok: false, error }
    }
    const municipality = input.municipality.trim()
    const zipCode = input.zipCode.trim()
    const minFareCentavos = Math.round(input.minFareCentavos)

    if (editingMarketId) {
      const existing = cities.value.find((city) => city.id === editingMarketId)
      if (!existing) {
        return { ok: false, error: `Municipality ${editingMarketId} was not found.` }
      }
      existing.municipality = municipality
      existing.zipCode = zipCode
      existing.minFareCentavos = minFareCentavos
      existing.requireTodaMtop = input.requireTodaMtop
      existing.status = input.status
      appendAuditEntry({
        action: 'MUNICIPAL_MARKET_UPDATED',
        targetEntity: `${existing.id} (${municipality})`,
        severity: 'Info',
        payload: { minFareCentavos, status: input.status },
      })
      return { ok: true, message: `Updated municipal market rules for ${municipality}.` }
    }

    const code = `MKT-ZDS-${zipCode}`
    cities.value.push({
      id: code,
      municipality,
      province: 'Zamboanga del Sur',
      zipCode,
      centerCoords: '7.83° N, 123.44° E',
      minFareCentavos,
      requireTodaMtop: input.requireTodaMtop,
      status: input.status,
    })
    appendAuditEntry({
      action: 'MUNICIPAL_MARKET_CREATED',
      targetEntity: `${code} (${municipality})`,
      severity: 'Info',
      payload: { zipCode, minFareCentavos, status: input.status },
    })
    return { ok: true, message: `Registered regional municipality ${municipality} (${code}).` }
  }

  return {
    cities,
    saveMunicipality,
  }
}

export function useServiceZones() {
  function saveServiceZone(
    editingZoneId: string | null,
    input: SaveServiceZoneInput,
  ): MutationResult & { message?: string } {
    const error = validateServiceZoneInput(input, platformConfig.value.maxBiddingSurgeCap)
    if (error) {
      return { ok: false, error }
    }
    const name = input.name.trim()
    const barangaysCovered = input.barangaysCovered.trim()
    const centerCoords = input.centerCoords.trim() || '7.8257° N, 123.4370° E'
    const surgeFactor = Number(input.surgeFactor.toFixed(1))
    const polygonPoints = Math.round(input.polygonPoints)

    if (editingZoneId) {
      const existing = serviceZones.value.find((zone) => zone.id === editingZoneId)
      if (!existing) {
        return { ok: false, error: `Service zone ${editingZoneId} was not found.` }
      }
      existing.name = name
      existing.barangaysCovered = barangaysCovered
      existing.centerCoords = centerCoords
      existing.surgeFactor = surgeFactor
      existing.polygonPoints = polygonPoints
      existing.status = input.status
      appendAuditEntry({
        action: 'SERVICE_ZONE_UPDATED',
        targetEntity: `${existing.id} (${name})`,
        severity: 'Warning',
        payload: { surgeFactor, status: input.status },
      })
      return {
        ok: true,
        message: `Updated geofence zone ${name} (${surgeFactor.toFixed(1)}x cap).`,
      }
    }

    const nextId = `ZN-PAG-${String(serviceZones.value.length + 1).padStart(2, '0')}`
    serviceZones.value.unshift({
      id: nextId,
      name,
      barangaysCovered,
      centerCoords,
      surgeFactor,
      polygonPoints,
      activeDrivers: 0,
      status: input.status,
    })
    appendAuditEntry({
      action: 'SERVICE_ZONE_CREATED',
      targetEntity: `${nextId} (${name})`,
      severity: 'Info',
      payload: { surgeFactor, polygonPoints, status: input.status },
    })
    return { ok: true, message: `Created geofence zone ${nextId}: ${name}.` }
  }

  return {
    zones: serviceZones,
    saveServiceZone,
  }
}

export function useLegalPolicies() {
  function publishDocument(
    documentId: string,
    input: SaveLegalDocumentInput,
  ): MutationResult & { message?: string } {
    const error = validateLegalDocumentInput(input)
    if (error) {
      return { ok: false, error }
    }
    const existing = legalDocuments.value.find((doc) => doc.id === documentId)
    if (!existing) {
      return { ok: false, error: `Policy document ${documentId} was not found.` }
    }
    existing.title = input.title.trim()
    existing.markdownBody = input.markdownBody.trim()
    if (input.bumpMinor) {
      existing.versionMinor += 1
    }
    existing.lastUpdated = 'Updated Just Now'
    const version = `v${existing.versionMajor}.${existing.versionMinor}`
    appendAuditEntry({
      action: 'LEGAL_POLICY_PUBLISHED',
      targetEntity: `${existing.id} ${version}`,
      severity: 'Warning',
      payload: { title: existing.title, version },
    })
    return { ok: true, message: `Published ${existing.id} ${version}.` }
  }

  return {
    documents: legalDocuments,
    publishDocument,
  }
}

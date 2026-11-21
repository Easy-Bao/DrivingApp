import { computed, ref } from 'vue'
import { ROLE_PROFILES, getAuthSession } from '@/core'
import {
  INITIAL_AUDIT_LOGS,
  INITIAL_CITIES,
  INITIAL_DOCUMENT_REQUIREMENTS,
  INITIAL_EMERGENCY_HOTLINES,
  INITIAL_FARE_DISCOUNTS,
  INITIAL_LEGAL_DOCUMENTS,
  INITIAL_SERVICE_ZONES,
  INITIAL_VEHICLE_CLASSES,
} from '@/features/settings/data/settings.seed'
import {
  DEFAULT_APP_SYSTEM_CONFIG,
  DEFAULT_COMPLIANCE_POLICY,
  DEFAULT_DISPATCH_POLICY,
  DEFAULT_PLATFORM_CONFIG,
  DEFAULT_PRICING_POLICY,
  DEFAULT_SAFETY_POLICY,
  DEFAULT_WALLET_POLICY,
  clonePlatformConfig,
} from '@/features/settings/domain/platform-config'
import {
  validateAppSystemConfig,
  validateCompliancePolicy,
  validateDispatchPolicy,
  validateDocumentRequirementInput,
  validateEmergencyHotlineInput,
  validateFareDiscountInput,
  validateLegalDocumentInput,
  validateMunicipalityInput,
  validatePlatformConfig,
  validatePricingPolicy,
  validateSafetyPolicy,
  validateServiceZoneInput,
  validateVehicleClassInput,
  validateWalletPolicy,
} from '@/features/settings/domain/validation'
import type {
  AppSystemConfig,
  AppendAuditLogInput,
  AuditLogEntry,
  CompliancePolicyConfig,
  DispatchPolicyConfig,
  DocumentRequirementRule,
  EmergencyHotline,
  FareDiscountRule,
  LegalDocument,
  MunicipalityMarket,
  MutationResult,
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
  ServiceZone,
  VehicleClassConfig,
  WalletPolicyConfig,
} from '@/features/settings/types'

const platformConfig = ref<PlatformConfig>(clonePlatformConfig(DEFAULT_PLATFORM_CONFIG))
const pricingPolicy = ref<PricingPolicyConfig>({ ...DEFAULT_PRICING_POLICY })
const fareDiscounts = ref<FareDiscountRule[]>(structuredClone([...INITIAL_FARE_DISCOUNTS]))
const walletPolicy = ref<WalletPolicyConfig>({ ...DEFAULT_WALLET_POLICY })
const dispatchPolicy = ref<DispatchPolicyConfig>({ ...DEFAULT_DISPATCH_POLICY })
const vehicleClasses = ref<VehicleClassConfig[]>(structuredClone([...INITIAL_VEHICLE_CLASSES]))
const compliancePolicy = ref<CompliancePolicyConfig>({ ...DEFAULT_COMPLIANCE_POLICY })
const documentRequirements = ref<DocumentRequirementRule[]>(
  structuredClone([...INITIAL_DOCUMENT_REQUIREMENTS]),
)
const safetyPolicy = ref<SafetyPolicyConfig>({ ...DEFAULT_SAFETY_POLICY })
const emergencyHotlines = ref<EmergencyHotline[]>(structuredClone([...INITIAL_EMERGENCY_HOTLINES]))
const appSystemConfig = ref<AppSystemConfig>({ ...DEFAULT_APP_SYSTEM_CONFIG })

const auditLogs = ref<AuditLogEntry[]>(structuredClone([...INITIAL_AUDIT_LOGS]))
const cities = ref<MunicipalityMarket[]>(structuredClone([...INITIAL_CITIES]))
const serviceZones = ref<ServiceZone[]>(structuredClone([...INITIAL_SERVICE_ZONES]))
const legalDocuments = ref<LegalDocument[]>(structuredClone([...INITIAL_LEGAL_DOCUMENTS]))

let auditSequence = 8905

function resolveActiveOperator(): { actor: string; role: string } {
  const session = getAuthSession()
  const roleLabel = session.role ? ROLE_PROFILES[session.role].label : ROLE_PROFILES.admin.label
  return {
    actor: session.operatorName || ROLE_PROFILES.admin.operatorName,
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
    ipAddress: '103.164.28.41',
    severity: input.severity,
    timestamp: 'Just Now · PHT',
    payloadDiff: JSON.stringify(input.payload),
  }
  auditLogs.value.unshift(entry)
  return entry
}

function syncSubPoliciesFromPlatform(next: PlatformConfig): void {
  pricingPolicy.value = {
    ...pricingPolicy.value,
    baseFareCentavos: next.baseFareCentavos,
    cancellationFeeCentavos: next.cancellationFeeCentavos,
    maxBiddingSurgeCap: next.maxBiddingSurgeCap,
    enableSurgePricing: next.enableSurgePricing,
    ratingBonusThreshold: next.ratingBonusThreshold,
    ratingBonusMultiplier: next.ratingBonusMultiplier,
  }
  walletPolicy.value = {
    ...walletPolicy.value,
    minWalletBalanceCentavos: next.minWalletBalanceCentavos,
    lowBalanceWarningCentavos: Math.max(
      walletPolicy.value.lowBalanceWarningCentavos,
      next.minWalletBalanceCentavos,
    ),
    autoLockLowBalanceDispatch: next.autoLockLowBalanceDispatch,
  }
  dispatchPolicy.value = {
    ...dispatchPolicy.value,
    biddingWindowSeconds: next.biddingWindowSeconds,
    gpsBeaconIntervalSeconds: next.gpsBeaconIntervalSeconds,
  }
  compliancePolicy.value = {
    ...compliancePolicy.value,
    enforceDocumentGate: next.enforceDocumentGate,
  }
}

export function resetSettingsForTesting(): void {
  platformConfig.value = clonePlatformConfig(DEFAULT_PLATFORM_CONFIG)
  pricingPolicy.value = { ...DEFAULT_PRICING_POLICY }
  fareDiscounts.value = structuredClone([...INITIAL_FARE_DISCOUNTS])
  walletPolicy.value = { ...DEFAULT_WALLET_POLICY }
  dispatchPolicy.value = { ...DEFAULT_DISPATCH_POLICY }
  vehicleClasses.value = structuredClone([...INITIAL_VEHICLE_CLASSES])
  compliancePolicy.value = { ...DEFAULT_COMPLIANCE_POLICY }
  documentRequirements.value = structuredClone([...INITIAL_DOCUMENT_REQUIREMENTS])
  safetyPolicy.value = { ...DEFAULT_SAFETY_POLICY }
  emergencyHotlines.value = structuredClone([...INITIAL_EMERGENCY_HOTLINES])
  appSystemConfig.value = { ...DEFAULT_APP_SYSTEM_CONFIG }
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
    syncSubPoliciesFromPlatform(normalized)
    appendAuditEntry({
      action: 'RUNTIME_CONFIG_UPDATED',
      targetEntity: 'Platform Preferences',
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
    syncSubPoliciesFromPlatform(platformConfig.value)
  }

  return {
    config: platformConfig,
    commitConfig,
    resetToDefaults,
  }
}

export function usePricingPolicy() {
  function commitPricingPolicy(next: PricingPolicyConfig, auditReason: string): MutationResult {
    const trimmedReason = auditReason.trim()
    if (!trimmedReason) {
      return { ok: false, error: 'Provide a change control note before saving pricing policy.' }
    }
    const validationError = validatePricingPolicy(next)
    if (validationError) {
      return { ok: false, error: validationError }
    }
    const normalized: PricingPolicyConfig = {
      baseFareCentavos: Math.round(next.baseFareCentavos),
      cancellationFeeCentavos: Math.round(next.cancellationFeeCentavos),
      cancellationGraceMinutes: Math.round(next.cancellationGraceMinutes),
      maxBiddingSurgeCap: Number(next.maxBiddingSurgeCap.toFixed(2)),
      enableSurgePricing: Boolean(next.enableSurgePricing),
      ratingBonusThreshold: Number(next.ratingBonusThreshold.toFixed(1)),
      ratingBonusMultiplier: Number(next.ratingBonusMultiplier.toFixed(2)),
      lowRatingSurgePenaltyMultiplier: Number(next.lowRatingSurgePenaltyMultiplier.toFixed(2)),
      enableNightDifferential: Boolean(next.enableNightDifferential),
      nightDifferentialPercent: Math.round(next.nightDifferentialPercent),
      nightStartHour: Math.round(next.nightStartHour),
      nightEndHour: Math.round(next.nightEndHour),
    }
    pricingPolicy.value = normalized
    platformConfig.value = {
      ...platformConfig.value,
      baseFareCentavos: normalized.baseFareCentavos,
      cancellationFeeCentavos: normalized.cancellationFeeCentavos,
      maxBiddingSurgeCap: normalized.maxBiddingSurgeCap,
      enableSurgePricing: normalized.enableSurgePricing,
      ratingBonusThreshold: normalized.ratingBonusThreshold,
      ratingBonusMultiplier: normalized.ratingBonusMultiplier,
    }
    appendAuditEntry({
      action: 'PRICING_POLICY_UPDATED',
      targetEntity: 'Global Fare & Surge Policy',
      severity: 'Warning',
      payload: {
        reason: trimmedReason,
        maxBiddingSurgeCap: normalized.maxBiddingSurgeCap,
        ratingBonusThreshold: normalized.ratingBonusThreshold,
        ratingBonusMultiplier: normalized.ratingBonusMultiplier,
        lowRatingSurgePenaltyMultiplier: normalized.lowRatingSurgePenaltyMultiplier,
        cancellationGraceMinutes: normalized.cancellationGraceMinutes,
        enableNightDifferential: normalized.enableNightDifferential,
      },
    })
    return { ok: true, message: 'Saved global fare, surge, and rating pricing policy.' }
  }

  function resetPricingDefaults(): void {
    pricingPolicy.value = { ...DEFAULT_PRICING_POLICY }
    platformConfig.value = {
      ...platformConfig.value,
      baseFareCentavos: DEFAULT_PRICING_POLICY.baseFareCentavos,
      cancellationFeeCentavos: DEFAULT_PRICING_POLICY.cancellationFeeCentavos,
      maxBiddingSurgeCap: DEFAULT_PRICING_POLICY.maxBiddingSurgeCap,
      enableSurgePricing: DEFAULT_PRICING_POLICY.enableSurgePricing,
      ratingBonusThreshold: DEFAULT_PRICING_POLICY.ratingBonusThreshold,
      ratingBonusMultiplier: DEFAULT_PRICING_POLICY.ratingBonusMultiplier,
    }
  }

  function saveDiscountRule(
    editingId: string | null,
    input: SaveFareDiscountInput,
  ): MutationResult {
    const error = validateFareDiscountInput(input)
    if (error) {
      return { ok: false, error }
    }
    const name = input.name.trim()
    const legalReference = input.legalReference.trim()
    const discountPercent = Math.round(input.discountPercent)

    if (editingId) {
      const existing = fareDiscounts.value.find((rule) => rule.id === editingId)
      if (!existing) {
        return { ok: false, error: `Discount rule ${editingId} was not found.` }
      }
      existing.name = name
      existing.eligibilityType = input.eligibilityType
      existing.discountPercent = discountPercent
      existing.requiresVerificationId = Boolean(input.requiresVerificationId)
      existing.legalReference = legalReference
      appendAuditEntry({
        action: 'FARE_DISCOUNT_UPDATED',
        targetEntity: `${existing.id} (${name})`,
        severity: 'Info',
        payload: { discountPercent, eligibilityType: input.eligibilityType },
      })
      return { ok: true, message: `Updated ${name} (${discountPercent}%).` }
    }

    const nextId = `DISC-${String(fareDiscounts.value.length + 1).padStart(2, '0')}`
    fareDiscounts.value.push({
      id: nextId,
      name,
      eligibilityType: input.eligibilityType,
      discountPercent,
      requiresVerificationId: Boolean(input.requiresVerificationId),
      legalReference,
      isActive: true,
    })
    appendAuditEntry({
      action: 'FARE_DISCOUNT_CREATED',
      targetEntity: `${nextId} (${name})`,
      severity: 'Info',
      payload: { discountPercent, eligibilityType: input.eligibilityType },
    })
    return { ok: true, message: `Created fare discount rule ${name} (${discountPercent}%).` }
  }

  function toggleDiscountRule(id: string): MutationResult {
    const target = fareDiscounts.value.find((rule) => rule.id === id)
    if (!target) {
      return { ok: false, error: `Discount rule ${id} was not found.` }
    }
    target.isActive = !target.isActive
    appendAuditEntry({
      action: 'FARE_DISCOUNT_TOGGLED',
      targetEntity: `${target.id} (${target.name})`,
      severity: 'Warning',
      payload: { isActive: target.isActive },
    })
    return {
      ok: true,
      message: `${target.name} is now ${target.isActive ? 'Active' : 'Paused'}.`,
    }
  }

  return {
    policy: pricingPolicy,
    discounts: fareDiscounts,
    commitPricingPolicy,
    resetPricingDefaults,
    saveDiscountRule,
    toggleDiscountRule,
  }
}

export function useWalletPolicy() {
  function commitWalletPolicy(next: WalletPolicyConfig, auditReason: string): MutationResult {
    const trimmedReason = auditReason.trim()
    if (!trimmedReason) {
      return { ok: false, error: 'Provide a change control note before saving wallet rules.' }
    }
    const validationError = validateWalletPolicy(next)
    if (validationError) {
      return { ok: false, error: validationError }
    }
    const normalized: WalletPolicyConfig = {
      minWalletBalanceCentavos: Math.round(next.minWalletBalanceCentavos),
      lowBalanceWarningCentavos: Math.round(next.lowBalanceWarningCentavos),
      minTopUpAmountCentavos: Math.round(next.minTopUpAmountCentavos),
      maxTopUpAmountCentavos: Math.round(next.maxTopUpAmountCentavos),
      autoLockLowBalanceDispatch: Boolean(next.autoLockLowBalanceDispatch),
      requireReceiptProof: Boolean(next.requireReceiptProof),
      topUpVerificationSlaMinutes: Math.round(next.topUpVerificationSlaMinutes),
    }
    walletPolicy.value = normalized
    platformConfig.value = {
      ...platformConfig.value,
      minWalletBalanceCentavos: normalized.minWalletBalanceCentavos,
      autoLockLowBalanceDispatch: normalized.autoLockLowBalanceDispatch,
    }
    appendAuditEntry({
      action: 'WALLET_POLICY_UPDATED',
      targetEntity: 'Driver Wallet & Top-Up Policy',
      severity: 'Warning',
      payload: {
        reason: trimmedReason,
        minWalletBalanceCentavos: normalized.minWalletBalanceCentavos,
        lowBalanceWarningCentavos: normalized.lowBalanceWarningCentavos,
        minTopUpAmountCentavos: normalized.minTopUpAmountCentavos,
        maxTopUpAmountCentavos: normalized.maxTopUpAmountCentavos,
        autoLockLowBalanceDispatch: normalized.autoLockLowBalanceDispatch,
      },
    })
    return { ok: true, message: 'Saved driver prepaid wallet and top-up rules.' }
  }

  function resetWalletDefaults(): void {
    walletPolicy.value = { ...DEFAULT_WALLET_POLICY }
    platformConfig.value = {
      ...platformConfig.value,
      minWalletBalanceCentavos: DEFAULT_WALLET_POLICY.minWalletBalanceCentavos,
      autoLockLowBalanceDispatch: DEFAULT_WALLET_POLICY.autoLockLowBalanceDispatch,
    }
  }

  return {
    policy: walletPolicy,
    commitWalletPolicy,
    resetWalletDefaults,
  }
}

export function useDispatchPolicy() {
  function commitDispatchPolicy(next: DispatchPolicyConfig, auditReason: string): MutationResult {
    const trimmedReason = auditReason.trim()
    if (!trimmedReason) {
      return { ok: false, error: 'Provide a change control note before saving dispatch policy.' }
    }
    const validationError = validateDispatchPolicy(next)
    if (validationError) {
      return { ok: false, error: validationError }
    }
    const normalized: DispatchPolicyConfig = {
      biddingWindowSeconds: Math.round(next.biddingWindowSeconds),
      dispatchSearchRadiusKm: Number(next.dispatchSearchRadiusKm.toFixed(1)),
      maxOffersPerSession: Math.round(next.maxOffersPerSession),
      minPassengerBidPercent: Math.round(next.minPassengerBidPercent),
      maxPassengerBidPercent: Math.round(next.maxPassengerBidPercent),
      gpsBeaconIntervalSeconds: Math.round(next.gpsBeaconIntervalSeconds),
      driverLocationMaxAgeSeconds: Math.round(next.driverLocationMaxAgeSeconds),
      passengerNoShowWaitMinutes: Math.round(next.passengerNoShowWaitMinutes),
      arrivalRadiusMeters: Math.round(next.arrivalRadiusMeters),
      completionRadiusMeters: Math.round(next.completionRadiusMeters),
      allowManualDispatchOverride: Boolean(next.allowManualDispatchOverride),
    }
    dispatchPolicy.value = normalized
    platformConfig.value = {
      ...platformConfig.value,
      biddingWindowSeconds: normalized.biddingWindowSeconds,
      gpsBeaconIntervalSeconds: normalized.gpsBeaconIntervalSeconds,
    }
    appendAuditEntry({
      action: 'DISPATCH_POLICY_UPDATED',
      targetEntity: 'Dispatch & Ride Lifecycle Policy',
      severity: 'Warning',
      payload: {
        reason: trimmedReason,
        biddingWindowSeconds: normalized.biddingWindowSeconds,
        dispatchSearchRadiusKm: normalized.dispatchSearchRadiusKm,
        driverLocationMaxAgeSeconds: normalized.driverLocationMaxAgeSeconds,
        passengerNoShowWaitMinutes: normalized.passengerNoShowWaitMinutes,
        arrivalRadiusMeters: normalized.arrivalRadiusMeters,
        completionRadiusMeters: normalized.completionRadiusMeters,
      },
    })
    return { ok: true, message: 'Saved dispatch, bidding, and ride lifecycle parameters.' }
  }

  function resetDispatchDefaults(): void {
    dispatchPolicy.value = { ...DEFAULT_DISPATCH_POLICY }
    platformConfig.value = {
      ...platformConfig.value,
      biddingWindowSeconds: DEFAULT_DISPATCH_POLICY.biddingWindowSeconds,
      gpsBeaconIntervalSeconds: DEFAULT_DISPATCH_POLICY.gpsBeaconIntervalSeconds,
    }
  }

  return {
    policy: dispatchPolicy,
    commitDispatchPolicy,
    resetDispatchDefaults,
  }
}

export function useVehicleClasses() {
  function saveVehicleClass(
    editingId: string | null,
    input: SaveVehicleClassInput,
  ): MutationResult {
    const error = validateVehicleClassInput(input)
    if (error) {
      return { ok: false, error }
    }
    const name = input.name.trim()
    const code = input.code.trim().toUpperCase()
    const description = input.description.trim()
    const passengerCapacity = Math.round(input.passengerCapacity)

    if (editingId) {
      const existing = vehicleClasses.value.find((item) => item.id === editingId)
      if (!existing) {
        return { ok: false, error: `Vehicle class ${editingId} was not found.` }
      }
      existing.name = name
      existing.code = code
      existing.description = description
      existing.passengerCapacity = passengerCapacity
      existing.fareRuleId = input.fareRuleId
      existing.commissionTierId = input.commissionTierId
      existing.isElectric = Boolean(input.isElectric)
      appendAuditEntry({
        action: 'VEHICLE_CLASS_UPDATED',
        targetEntity: `${existing.id} (${name})`,
        severity: 'Info',
        payload: {
          code,
          passengerCapacity,
          fareRuleId: input.fareRuleId,
          commissionTierId: input.commissionTierId,
        },
      })
      return { ok: true, message: `Updated vehicle class ${name}.` }
    }

    const nextId = `CLS-${code.replace(/[^A-Z0-9]+/g, '-')}-${vehicleClasses.value.length + 1}`
    vehicleClasses.value.push({
      id: nextId,
      name,
      code,
      description,
      passengerCapacity,
      fareRuleId: input.fareRuleId,
      commissionTierId: input.commissionTierId,
      isElectric: Boolean(input.isElectric),
      isActive: true,
    })
    appendAuditEntry({
      action: 'VEHICLE_CLASS_CREATED',
      targetEntity: `${nextId} (${name})`,
      severity: 'Info',
      payload: { code, passengerCapacity, fareRuleId: input.fareRuleId },
    })
    return { ok: true, message: `Added vehicle class ${name} (${code}).` }
  }

  function toggleVehicleClass(id: string): MutationResult {
    const target = vehicleClasses.value.find((item) => item.id === id)
    if (!target) {
      return { ok: false, error: `Vehicle class ${id} was not found.` }
    }
    target.isActive = !target.isActive
    appendAuditEntry({
      action: 'VEHICLE_CLASS_TOGGLED',
      targetEntity: `${target.id} (${target.name})`,
      severity: 'Warning',
      payload: { isActive: target.isActive },
    })
    return {
      ok: true,
      message: `${target.name} marked ${target.isActive ? 'Active' : 'Paused'}.`,
    }
  }

  return {
    vehicleClasses,
    saveVehicleClass,
    toggleVehicleClass,
  }
}

export function useComplianceRules() {
  function commitCompliancePolicy(
    next: CompliancePolicyConfig,
    auditReason: string,
  ): MutationResult {
    const trimmedReason = auditReason.trim()
    if (!trimmedReason) {
      return { ok: false, error: 'Provide a change control note before saving compliance rules.' }
    }
    const validationError = validateCompliancePolicy(next)
    if (validationError) {
      return { ok: false, error: validationError }
    }
    const normalized: CompliancePolicyConfig = {
      enforceDocumentGate: Boolean(next.enforceDocumentGate),
      expiryWarningLeadDays: Math.round(next.expiryWarningLeadDays),
      criticalExpiryDays: Math.round(next.criticalExpiryDays),
      expiryGracePeriodDays: Math.round(next.expiryGracePeriodDays),
      autoSuspendOnExpiry: Boolean(next.autoSuspendOnExpiry),
    }
    compliancePolicy.value = normalized
    platformConfig.value = {
      ...platformConfig.value,
      enforceDocumentGate: normalized.enforceDocumentGate,
    }
    appendAuditEntry({
      action: 'COMPLIANCE_POLICY_UPDATED',
      targetEntity: 'Driver Document Compliance Gate',
      severity: 'Warning',
      payload: {
        reason: trimmedReason,
        ...normalized,
      },
    })
    return { ok: true, message: 'Saved document gate and expiry enforcement rules.' }
  }

  function resetComplianceDefaults(): void {
    compliancePolicy.value = { ...DEFAULT_COMPLIANCE_POLICY }
    platformConfig.value = {
      ...platformConfig.value,
      enforceDocumentGate: DEFAULT_COMPLIANCE_POLICY.enforceDocumentGate,
    }
  }

  function saveDocumentRequirement(
    editingId: string | null,
    input: SaveDocumentRequirementInput,
  ): MutationResult {
    const error = validateDocumentRequirementInput(input)
    if (error) {
      return { ok: false, error }
    }
    const name = input.name.trim()
    const issuingAuthority = input.issuingAuthority.trim()

    if (editingId) {
      const existing = documentRequirements.value.find((doc) => doc.id === editingId)
      if (!existing) {
        return { ok: false, error: `Document rule ${editingId} was not found.` }
      }
      existing.name = name
      existing.scope = input.scope
      existing.issuingAuthority = issuingAuthority
      existing.mandatory = Boolean(input.mandatory)
      existing.requiresTwoSides = Boolean(input.requiresTwoSides)
      existing.tracksExpiry = Boolean(input.tracksExpiry)
      appendAuditEntry({
        action: 'DOCUMENT_RULE_UPDATED',
        targetEntity: `${existing.id} (${name})`,
        severity: 'Info',
        payload: { scope: input.scope, mandatory: existing.mandatory },
      })
      return { ok: true, message: `Updated compliance document rule: ${name}.` }
    }

    const nextId = `DOC-RULE-${String(documentRequirements.value.length + 1).padStart(2, '0')}`
    documentRequirements.value.push({
      id: nextId,
      name,
      scope: input.scope,
      issuingAuthority,
      mandatory: Boolean(input.mandatory),
      requiresTwoSides: Boolean(input.requiresTwoSides),
      tracksExpiry: Boolean(input.tracksExpiry),
      isActive: true,
    })
    appendAuditEntry({
      action: 'DOCUMENT_RULE_CREATED',
      targetEntity: `${nextId} (${name})`,
      severity: 'Info',
      payload: { scope: input.scope, mandatory: input.mandatory },
    })
    return { ok: true, message: `Added compliance document rule: ${name}.` }
  }

  function toggleDocumentRequirement(id: string): MutationResult {
    const target = documentRequirements.value.find((doc) => doc.id === id)
    if (!target) {
      return { ok: false, error: `Document rule ${id} was not found.` }
    }
    target.isActive = !target.isActive
    appendAuditEntry({
      action: 'DOCUMENT_RULE_TOGGLED',
      targetEntity: `${target.id} (${target.name})`,
      severity: 'Warning',
      payload: { isActive: target.isActive },
    })
    return {
      ok: true,
      message: `${target.name} is now ${target.isActive ? 'Active' : 'Archived'}.`,
    }
  }

  return {
    policy: compliancePolicy,
    requirements: documentRequirements,
    commitCompliancePolicy,
    resetComplianceDefaults,
    saveDocumentRequirement,
    toggleDocumentRequirement,
  }
}

export function useSafetyConfig() {
  const primaryHotline = computed(
    () =>
      emergencyHotlines.value.find((hotline) => hotline.isPrimary && hotline.isActive) ??
      emergencyHotlines.value.find((hotline) => hotline.isActive) ??
      emergencyHotlines.value[0] ??
      null,
  )

  const primaryHotlineLabel = computed(() => {
    const primary = primaryHotline.value
    if (!primary) return '911 · CDRRMO (062-925-0911)'
    return `${primary.label} (${primary.phone})`
  })

  function commitSafetyPolicy(next: SafetyPolicyConfig, auditReason: string): MutationResult {
    const trimmedReason = auditReason.trim()
    if (!trimmedReason) {
      return { ok: false, error: 'Provide a change control note before saving safety policy.' }
    }
    const validationError = validateSafetyPolicy(next)
    if (validationError) {
      return { ok: false, error: validationError }
    }
    const normalized: SafetyPolicyConfig = {
      sosAutoEscalateSeconds: Math.round(next.sosAutoEscalateSeconds),
      sosLocationPingSeconds: Math.round(next.sosLocationPingSeconds),
      autoNotifyRespondersOnCritical: Boolean(next.autoNotifyRespondersOnCritical),
      requireResolutionNote: Boolean(next.requireResolutionNote),
      autoSuspendOnCriticalReport: Boolean(next.autoSuspendOnCriticalReport),
    }
    safetyPolicy.value = normalized
    appendAuditEntry({
      action: 'SAFETY_POLICY_UPDATED',
      targetEntity: 'SOS & Safety Escalation Rules',
      severity: 'Warning',
      payload: {
        reason: trimmedReason,
        ...normalized,
      },
    })
    return { ok: true, message: 'Saved emergency SOS and safety escalation settings.' }
  }

  function resetSafetyDefaults(): void {
    safetyPolicy.value = { ...DEFAULT_SAFETY_POLICY }
  }

  function saveHotline(editingId: string | null, input: SaveEmergencyHotlineInput): MutationResult {
    const error = validateEmergencyHotlineInput(input)
    if (error) {
      return { ok: false, error }
    }
    const label = input.label.trim()
    const agency = input.agency.trim()
    const phone = input.phone.trim()
    const coverageArea = input.coverageArea.trim()

    if (input.isPrimary) {
      for (const hotline of emergencyHotlines.value) {
        hotline.isPrimary = false
      }
    }

    if (editingId) {
      const existing = emergencyHotlines.value.find((item) => item.id === editingId)
      if (!existing) {
        return { ok: false, error: `Hotline ${editingId} was not found.` }
      }
      existing.label = label
      existing.agency = agency
      existing.phone = phone
      existing.coverageArea = coverageArea
      existing.isPrimary = Boolean(input.isPrimary)
      appendAuditEntry({
        action: 'EMERGENCY_HOTLINE_UPDATED',
        targetEntity: `${existing.id} (${label})`,
        severity: 'Warning',
        payload: { phone, isPrimary: existing.isPrimary },
      })
      return { ok: true, message: `Updated emergency hotline ${label}.` }
    }

    const nextId = `HOT-${String(emergencyHotlines.value.length + 1).padStart(2, '0')}`
    emergencyHotlines.value.push({
      id: nextId,
      label,
      agency,
      phone,
      coverageArea,
      isPrimary: Boolean(input.isPrimary),
      isActive: true,
    })
    appendAuditEntry({
      action: 'EMERGENCY_HOTLINE_CREATED',
      targetEntity: `${nextId} (${label})`,
      severity: 'Info',
      payload: { phone, coverageArea },
    })
    return { ok: true, message: `Registered emergency hotline ${label}.` }
  }

  function toggleHotline(id: string): MutationResult {
    const target = emergencyHotlines.value.find((item) => item.id === id)
    if (!target) {
      return { ok: false, error: `Hotline ${id} was not found.` }
    }
    target.isActive = !target.isActive
    appendAuditEntry({
      action: 'EMERGENCY_HOTLINE_TOGGLED',
      targetEntity: `${target.id} (${target.label})`,
      severity: 'Warning',
      payload: { isActive: target.isActive },
    })
    return {
      ok: true,
      message: `${target.label} marked ${target.isActive ? 'Active' : 'Paused'}.`,
    }
  }

  return {
    policy: safetyPolicy,
    hotlines: emergencyHotlines,
    primaryHotline,
    primaryHotlineLabel,
    commitSafetyPolicy,
    resetSafetyDefaults,
    saveHotline,
    toggleHotline,
  }
}

export function useAppSystemConfig() {
  function commitSystemConfig(next: AppSystemConfig, auditReason: string): MutationResult {
    const trimmedReason = auditReason.trim()
    if (!trimmedReason) {
      return { ok: false, error: 'Provide a change control note before saving system settings.' }
    }
    const validationError = validateAppSystemConfig(next)
    if (validationError) {
      return { ok: false, error: validationError }
    }
    const normalized: AppSystemConfig = {
      reportingTimezone: next.reportingTimezone.trim(),
      supportEmail: next.supportEmail.trim(),
      supportPhone: next.supportPhone.trim(),
      passengerMinVersion: next.passengerMinVersion.trim(),
      driverMinVersion: next.driverMinVersion.trim(),
      enforceMinAppVersion: Boolean(next.enforceMinAppVersion),
      maintenanceMode: Boolean(next.maintenanceMode),
      maintenanceNotice: next.maintenanceNotice.trim(),
    }
    appSystemConfig.value = normalized
    appendAuditEntry({
      action: 'APP_SYSTEM_CONFIG_UPDATED',
      targetEntity: 'App & System Configuration',
      severity: normalized.maintenanceMode ? 'Critical' : 'Warning',
      payload: {
        reason: trimmedReason,
        reportingTimezone: normalized.reportingTimezone,
        passengerMinVersion: normalized.passengerMinVersion,
        driverMinVersion: normalized.driverMinVersion,
        maintenanceMode: normalized.maintenanceMode,
      },
    })
    return { ok: true, message: 'Saved application release gates and system configuration.' }
  }

  function resetSystemDefaults(): void {
    appSystemConfig.value = { ...DEFAULT_APP_SYSTEM_CONFIG }
  }

  return {
    systemConfig: appSystemConfig,
    commitSystemConfig,
    resetSystemDefaults,
  }
}

export function useCities() {
  function saveMunicipality(
    editingMarketId: string | null,
    input: SaveMunicipalityInput,
  ): MutationResult {
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
  ): MutationResult {
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
  function publishDocument(documentId: string, input: SaveLegalDocumentInput): MutationResult {
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

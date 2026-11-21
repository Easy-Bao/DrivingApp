import { beforeEach, describe, expect, it } from 'vitest'
import { loginOperator } from '@/core'
import {
  DEFAULT_APP_SYSTEM_CONFIG,
  DEFAULT_COMPLIANCE_POLICY,
  DEFAULT_DISPATCH_POLICY,
  DEFAULT_PLATFORM_CONFIG,
  DEFAULT_PRICING_POLICY,
  DEFAULT_SAFETY_POLICY,
  DEFAULT_WALLET_POLICY,
  resetSettingsForTesting,
  useAppSystemConfig,
  useAuditLogs,
  useCities,
  useComplianceRules,
  useDispatchPolicy,
  useLegalPolicies,
  usePlatformConfig,
  usePricingPolicy,
  useSafetyConfig,
  useServiceZones,
  useVehicleClasses,
  useWalletPolicy,
  validateAppSystemConfig,
  validateDispatchPolicy,
  validateLegalDocumentInput,
  validateMunicipalityInput,
  validatePlatformConfig,
  validatePricingPolicy,
  validateServiceZoneInput,
  validateWalletPolicy,
} from '@/features/settings'

describe('features/settings domain & composables', () => {
  beforeEach(() => {
    resetSettingsForTesting()
  })

  it('exposes canonical Pagadian platform defaults using integer centavos', () => {
    expect(DEFAULT_PLATFORM_CONFIG).toEqual({
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
    })
  })

  it('validates platform, pricing, wallet, dispatch, and app system configuration bounds cleanly', () => {
    expect(validatePlatformConfig(DEFAULT_PLATFORM_CONFIG)).toBeNull()
    expect(
      validatePlatformConfig({ ...DEFAULT_PLATFORM_CONFIG, biddingWindowSeconds: 10 }),
    ).toBeTruthy()
    expect(
      validatePlatformConfig({ ...DEFAULT_PLATFORM_CONFIG, maxBiddingSurgeCap: 3.0 }),
    ).toBeTruthy()
    expect(
      validatePlatformConfig({ ...DEFAULT_PLATFORM_CONFIG, ratingBonusThreshold: 5.5 }),
    ).toBeTruthy()
    expect(
      validatePlatformConfig({ ...DEFAULT_PLATFORM_CONFIG, minWalletBalanceCentavos: -100 }),
    ).toBeTruthy()

    expect(validatePricingPolicy(DEFAULT_PRICING_POLICY)).toBeNull()
    expect(
      validatePricingPolicy({ ...DEFAULT_PRICING_POLICY, lowRatingSurgePenaltyMultiplier: 1.5 }),
    ).toBeTruthy()
    expect(
      validatePricingPolicy({ ...DEFAULT_PRICING_POLICY, cancellationGraceMinutes: 20 }),
    ).toBeTruthy()

    expect(validateWalletPolicy(DEFAULT_WALLET_POLICY)).toBeNull()
    expect(
      validateWalletPolicy({
        ...DEFAULT_WALLET_POLICY,
        minWalletBalanceCentavos: 20000,
        lowBalanceWarningCentavos: 5000,
      }),
    ).toBeTruthy()

    expect(validateDispatchPolicy(DEFAULT_DISPATCH_POLICY)).toBeNull()
    expect(
      validateDispatchPolicy({
        ...DEFAULT_DISPATCH_POLICY,
        gpsBeaconIntervalSeconds: 30,
        driverLocationMaxAgeSeconds: 20,
      }),
    ).toBeTruthy()

    expect(validateAppSystemConfig(DEFAULT_APP_SYSTEM_CONFIG)).toBeNull()
    expect(
      validateAppSystemConfig({ ...DEFAULT_APP_SYSTEM_CONFIG, passengerMinVersion: 'v1' }),
    ).toBeTruthy()
  })

  it('commits valid runtime config changes and keeps sub-policies synchronized', () => {
    loginOperator('finance', '7016')
    const { config, commitConfig, resetToDefaults } = usePlatformConfig()
    const { policy: walletPolicy } = useWalletPolicy()
    const { policy: pricingPolicy } = usePricingPolicy()
    const { logs } = useAuditLogs()
    const initialCount = logs.value.length

    const failedNoReason = commitConfig({ ...config.value, minWalletBalanceCentavos: 7500 }, '   ')
    expect(failedNoReason.ok).toBe(false)
    expect(logs.value).toHaveLength(initialCount)

    const result = commitConfig(
      {
        ...config.value,
        minWalletBalanceCentavos: 7500,
        ratingBonusThreshold: 4.8,
      },
      'Updated weekly Pagadian TODA dispatch reserve.',
    )

    expect(result).toEqual({ ok: true })
    expect(config.value.minWalletBalanceCentavos).toBe(7500)
    expect(walletPolicy.value.minWalletBalanceCentavos).toBe(7500)
    expect(pricingPolicy.value.ratingBonusThreshold).toBe(4.8)
    expect(logs.value).toHaveLength(initialCount + 1)
    expect(logs.value[0]?.action).toBe('RUNTIME_CONFIG_UPDATED')
    expect(logs.value[0]?.actor).toBe('Clarisse Mendoza')
    expect(logs.value[0]?.payloadDiff).toContain('7500')

    resetToDefaults()
    expect(config.value.minWalletBalanceCentavos).toBe(5000)
    expect(walletPolicy.value.minWalletBalanceCentavos).toBe(5000)
  })

  it('commits independent pricing, wallet, dispatch, compliance, safety, vehicle class, and system configs', () => {
    const { config } = usePlatformConfig()
    const { policy: pricing, commitPricingPolicy, saveDiscountRule, discounts } = usePricingPolicy()
    const { policy: wallet, commitWalletPolicy } = useWalletPolicy()
    const { policy: dispatch, commitDispatchPolicy } = useDispatchPolicy()
    const { vehicleClasses, saveVehicleClass, toggleVehicleClass } = useVehicleClasses()
    const { commitCompliancePolicy, saveDocumentRequirement, requirements } = useComplianceRules()
    const { primaryHotlineLabel, commitSafetyPolicy, saveHotline } = useSafetyConfig()
    const { systemConfig, commitSystemConfig } = useAppSystemConfig()

    expect(
      commitPricingPolicy(
        { ...pricing.value, maxBiddingSurgeCap: 2.0, lowRatingSurgePenaltyMultiplier: 0.85 },
        'Adjusted surge and rating guardrails.',
      ).ok,
    ).toBe(true)
    expect(config.value.maxBiddingSurgeCap).toBe(2.0)

    expect(
      saveDiscountRule(null, {
        name: 'Solo Parent Discount',
        eligibilityType: 'Promotional',
        discountPercent: 10,
        requiresVerificationId: true,
        legalReference: 'City Ordinance 2026-12',
      }).ok,
    ).toBe(true)
    expect(discounts.value.some((rule) => rule.name === 'Solo Parent Discount')).toBe(true)

    expect(
      commitWalletPolicy(
        {
          ...wallet.value,
          minWalletBalanceCentavos: 8000,
          lowBalanceWarningCentavos: 15000,
          minTopUpAmountCentavos: 10000,
        },
        'Aligned top-up floor.',
      ).ok,
    ).toBe(true)
    expect(config.value.minWalletBalanceCentavos).toBe(8000)

    expect(
      commitDispatchPolicy(
        { ...dispatch.value, biddingWindowSeconds: 60, passengerNoShowWaitMinutes: 7 },
        'Shortened bid timer.',
      ).ok,
    ).toBe(true)
    expect(config.value.biddingWindowSeconds).toBe(60)

    expect(
      saveVehicleClass(null, {
        name: 'Cargo Bao-Bao',
        code: 'BAO-CRG',
        description: 'Market goods transport.',
        passengerCapacity: 2,
        fareRuleId: 'baobao-express',
        commissionTierId: 'standard-fleet',
        isElectric: false,
      }).ok,
    ).toBe(true)
    const createdClass = vehicleClasses.value.find((item) => item.code === 'BAO-CRG')
    expect(createdClass).toBeDefined()
    expect(toggleVehicleClass(createdClass!.id).ok).toBe(true)
    expect(createdClass!.isActive).toBe(false)

    expect(
      commitCompliancePolicy(
        { ...DEFAULT_COMPLIANCE_POLICY, enforceDocumentGate: false, expiryWarningLeadDays: 45 },
        'Temporary onboarding grace.',
      ).ok,
    ).toBe(true)
    expect(config.value.enforceDocumentGate).toBe(false)
    expect(
      saveDocumentRequirement(null, {
        name: 'Barangay Clearance',
        scope: 'Driver',
        issuingAuthority: 'Barangay Hall',
        mandatory: false,
        requiresTwoSides: false,
        tracksExpiry: true,
      }).ok,
    ).toBe(true)
    expect(requirements.value.some((doc) => doc.name === 'Barangay Clearance')).toBe(true)

    expect(
      commitSafetyPolicy({ ...DEFAULT_SAFETY_POLICY, sosAutoEscalateSeconds: 45 }, 'Tighter SLA')
        .ok,
    ).toBe(true)
    expect(
      saveHotline(null, {
        label: 'ZDS Command',
        agency: 'Provincial Rescue',
        phone: '062-999-0911',
        coverageArea: 'Zamboanga del Sur',
        isPrimary: true,
      }).ok,
    ).toBe(true)
    expect(primaryHotlineLabel.value).toBe('ZDS Command (062-999-0911)')

    expect(
      commitSystemConfig(
        { ...DEFAULT_APP_SYSTEM_CONFIG, driverMinVersion: '1.5.0', maintenanceMode: true },
        'Scheduled migration.',
      ).ok,
    ).toBe(true)
    expect(systemConfig.value.maintenanceMode).toBe(true)
  })

  it('aligns seeded audit logs with canonical operators and TOP-8921 ₱500.00 top-up', () => {
    const { logs } = useAuditLogs()
    const topupLog = logs.value.find((entry) => entry.action === 'WALLET_TOPUP_VERIFIED')
    expect(topupLog).toBeDefined()
    expect(topupLog?.targetEntity).toContain('TOP-8921')
    expect(topupLog?.targetEntity).toContain('+₱500.00')
    expect(logs.value.map((entry) => entry.actor)).not.toContain('Maria Elena Santos')
    expect(logs.value.map((entry) => entry.actor)).not.toContain('Lorna Dela Cruz')
  })

  it('validates and mutates service zones against active platform surge ceiling', () => {
    const { config, commitConfig } = usePlatformConfig()
    commitConfig({ ...config.value, maxBiddingSurgeCap: 2.0 }, 'Tighten rain surge ceiling.')

    const { zones, saveServiceZone } = useServiceZones()
    const tooHighError = validateServiceZoneInput(
      {
        name: 'New Coastal Strip',
        barangaysCovered: 'Kawit, Santa Lucia',
        centerCoords: '7.82° N, 123.44° E',
        surgeFactor: 2.4,
        polygonPoints: 8,
        status: 'Active',
      },
      config.value.maxBiddingSurgeCap,
    )
    expect(tooHighError).toContain('2.0x')

    const created = saveServiceZone(null, {
      name: 'New Coastal Strip',
      barangaysCovered: 'Kawit, Santa Lucia',
      centerCoords: '7.82° N, 123.44° E',
      surgeFactor: 1.6,
      polygonPoints: 8,
      status: 'Active',
    })
    expect(created.ok).toBe(true)
    expect(zones.value[0]?.name).toBe('New Coastal Strip')
    expect(zones.value[0]?.id).toMatch(/^ZN-PAG-/)
  })

  it('validates and mutates municipal markets using integer centavos', () => {
    const invalidMinFare = validateMunicipalityInput({
      municipality: 'Aurora',
      zipCode: '7020',
      minFareCentavos: 1000,
      requireTodaMtop: true,
      status: 'Planned Expansion',
    })
    expect(invalidMinFare).toBeTruthy()

    const { cities, saveMunicipality } = useCities()
    const created = saveMunicipality(null, {
      municipality: 'Aurora',
      zipCode: '7020',
      minFareCentavos: 3500,
      requireTodaMtop: true,
      status: 'Planned Expansion',
    })
    expect(created.ok).toBe(true)
    expect(cities.value.some((city) => city.id === 'MKT-ZDS-7020')).toBe(true)
  })

  it('validates and publishes legal policy revisions', () => {
    expect(
      validateLegalDocumentInput({
        title: '',
        markdownBody: 'Body',
        bumpMinor: true,
      }),
    ).toBeTruthy()

    const { documents, publishDocument } = useLegalPolicies()
    const result = publishDocument('DOC-TOS-PH', {
      title: 'Passenger Terms of Service (Updated)',
      markdownBody: '# Updated Terms\n\nApplies to Pagadian City TODA dispatch.',
      bumpMinor: true,
    })
    expect(result.ok).toBe(true)
    const updated = documents.value.find((doc) => doc.id === 'DOC-TOS-PH')
    expect(updated?.versionMajor).toBe(2)
    expect(updated?.versionMinor).toBe(2)
    expect(updated?.lastUpdated).toBe('Updated Just Now')
  })
})

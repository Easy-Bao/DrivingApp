import { beforeEach, describe, expect, it } from 'vitest'
import { loginOperator } from '@/core'
import {
  DEFAULT_PLATFORM_CONFIG,
  resetSettingsForTesting,
  useAuditLogs,
  useCities,
  useLegalPolicies,
  usePlatformConfig,
  useServiceZones,
  validateLegalDocumentInput,
  validateMunicipalityInput,
  validatePlatformConfig,
  validateServiceZoneInput,
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

  it('validates platform configuration bounds cleanly', () => {
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
  })

  it('commits valid runtime config changes and records an audit log for the active operator', () => {
    loginOperator('finance', '7016')
    const { config, commitConfig, resetToDefaults } = usePlatformConfig()
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
    expect(config.value.ratingBonusThreshold).toBe(4.8)
    expect(logs.value).toHaveLength(initialCount + 1)
    expect(logs.value[0]?.action).toBe('RUNTIME_CONFIG_UPDATED')
    expect(logs.value[0]?.actor).toBe('Clarisse Mendoza')
    expect(logs.value[0]?.payloadDiff).toContain('7500')

    resetToDefaults()
    expect(config.value.minWalletBalanceCentavos).toBe(5000)
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

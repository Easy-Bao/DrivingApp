import { describe, expect, it } from 'vitest'
import { PRESET_CORRIDORS } from '@/features/fare-estimation/api/fare-estimation.api'
import { useFareEstimation } from '@/features/fare-estimation/composables/useFareEstimation'

describe('useFareEstimation', () => {
  it('initializes with a Pagadian corridor floor estimate', () => {
    const { request, estimate, validationError } = useFareEstimation()

    expect(validationError.value).toBeNull()
    expect(request.pickupLocation).toContain('Agora')
    expect(estimate.value).not.toBeNull()
    expect(estimate.value?.estimatedFareCents).toBeGreaterThanOrEqual(2500)
  })

  it('updates fare floor when switching preset corridors and vehicle tiers', async () => {
    const { selectPreset, selectTier, estimate, request } = useFareEstimation()

    const airportCorridor = PRESET_CORRIDORS.find((item) => item.id === 'tiguma-airport')
    expect(airportCorridor).toBeDefined()

    if (airportCorridor) {
      await selectPreset(airportCorridor)
      expect(request.destinationLocation).toBe(airportCorridor.destination)
      const standardFareCents = estimate.value?.estimatedFareCents ?? 0

      await selectTier('comfort')
      const uphillFareCents = estimate.value?.estimatedFareCents ?? 0
      expect(uphillFareCents).toBeGreaterThan(standardFareCents)
    }
  })

  it('validates missing locations before estimating', async () => {
    const { request, estimateFare, validationError } = useFareEstimation()

    request.pickupLocation = '   '
    await estimateFare()

    expect(validationError.value).toBe(
      'Enter both a Pagadian pickup landmark and drop-off location.',
    )
  })
})

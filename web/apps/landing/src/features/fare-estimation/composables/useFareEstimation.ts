import { reactive, ref } from 'vue'
import {
  PRESET_CORRIDORS,
  RIDE_TIER_CONFIGS,
  calculateFareEstimate,
} from '@/features/fare-estimation/api/fare-estimation.api'
import type {
  FareEstimateRequest,
  FareEstimateResult,
  PresetCorridor,
  RideTier,
} from '@/features/fare-estimation/types'

export interface FarePrefillPayload {
  pickupLocation?: string
  destinationLocation?: string
  rideTier: RideTier
  sequence: number
}

// Cross-section event bridge so service and zone showcase sections can update the hero calculator without global mutable form state across isolated test runs.
export const farePrefillSignal = ref<FarePrefillPayload | null>(null)

export function triggerFarePrefill(payload: {
  pickupLocation?: string
  destinationLocation?: string
  rideTier: RideTier
}) {
  const nextSequence = (farePrefillSignal.value?.sequence ?? 0) + 1
  farePrefillSignal.value = {
    ...payload,
    sequence: nextSequence,
  }

  if (typeof document !== 'undefined' && typeof window !== 'undefined') {
    const estimatorElement = document.getElementById('fare-estimator')
    if (estimatorElement && typeof estimatorElement.scrollIntoView === 'function') {
      const reducedMotion =
        typeof window.matchMedia === 'function' &&
        window.matchMedia('(prefers-reduced-motion: reduce)').matches
      estimatorElement.scrollIntoView({
        behavior: reducedMotion ? 'auto' : 'smooth',
        block: 'start',
      })
    }
  }
}

const INITIAL_PRESET = PRESET_CORRIDORS[0] ?? {
  id: 'default',
  label: 'Agora -> Dao Capitol',
  pickup: 'Agora Public Market, Poblacion',
  destination: 'Dao Provincial Capitol & Medical Center',
  distanceKm: 3.4,
  durationMinutes: 11,
  note: 'Includes uphill Capitol incline corridor',
}

function buildInitialEstimate(tier: RideTier): FareEstimateResult {
  const tierConfig = RIDE_TIER_CONFIGS[tier]
  const extraKm = Math.max(0, INITIAL_PRESET.distanceKm - 1)
  const floorPhp = Math.round(tierConfig.basePhp + extraKm * tierConfig.perKmPhp)

  return {
    estimatedFareCents: floorPhp * 100,
    estimatedDurationMinutes: INITIAL_PRESET.durationMinutes,
    estimatedDistanceKm: INITIAL_PRESET.distanceKm,
    baseFlagDownPhp: tierConfig.basePhp,
    suggestedBidRangePhp: {
      min: floorPhp,
      max: Math.round(floorPhp * 1.25),
    },
    surgeCapLabel: tierConfig.surgeCapText,
    corridorNote: INITIAL_PRESET.note,
  }
}

export function useFareEstimation() {
  const request = reactive<FareEstimateRequest>({
    pickupLocation: INITIAL_PRESET.pickup,
    destinationLocation: INITIAL_PRESET.destination,
    rideTier: 'standard',
  })

  const estimate = ref<FareEstimateResult | null>(buildInitialEstimate('standard'))
  const isCalculating = ref(false)
  const validationError = ref<string | null>(null)
  const activePresetId = ref<string | null>(INITIAL_PRESET.id)

  const estimateFare = async () => {
    const pickup = request.pickupLocation.trim()
    const destination = request.destinationLocation.trim()

    if (!pickup || !destination) {
      validationError.value = 'Enter both a Pagadian pickup landmark and drop-off location.'
      return
    }

    if (pickup.toLowerCase() === destination.toLowerCase()) {
      validationError.value = 'Pickup and destination must be different points.'
      return
    }

    validationError.value = null
    isCalculating.value = true
    try {
      estimate.value = await calculateFareEstimate({
        pickupLocation: pickup,
        destinationLocation: destination,
        rideTier: request.rideTier,
      })
    } finally {
      isCalculating.value = false
    }
  }

  const selectPreset = async (corridor: PresetCorridor) => {
    request.pickupLocation = corridor.pickup
    request.destinationLocation = corridor.destination
    activePresetId.value = corridor.id
    await estimateFare()
  }

  const selectTier = async (tier: RideTier) => {
    request.rideTier = tier
    await estimateFare()
  }

  const applyExternalPrefill = async (payload: {
    pickupLocation?: string
    destinationLocation?: string
    rideTier: RideTier
  }) => {
    if (payload.pickupLocation) {
      request.pickupLocation = payload.pickupLocation
    }
    if (payload.destinationLocation) {
      request.destinationLocation = payload.destinationLocation
    }
    request.rideTier = payload.rideTier
    activePresetId.value = null
    await estimateFare()
  }

  const swapLocations = async () => {
    const currentPickup = request.pickupLocation
    request.pickupLocation = request.destinationLocation
    request.destinationLocation = currentPickup
    activePresetId.value = null
    await estimateFare()
  }

  return {
    request,
    estimate,
    isCalculating,
    validationError,
    activePresetId,
    presets: PRESET_CORRIDORS,
    tierConfigs: RIDE_TIER_CONFIGS,
    estimateFare,
    selectPreset,
    selectTier,
    applyExternalPrefill,
    swapLocations,
  }
}

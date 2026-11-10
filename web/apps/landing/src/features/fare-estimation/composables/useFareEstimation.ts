import { reactive, ref } from 'vue'
import { calculateFareEstimate } from '@/features/fare-estimation/api/fare-estimation.api'
import type { FareEstimateRequest, FareEstimateResult } from '@/features/fare-estimation/types'

export function useFareEstimation() {
  const request = reactive<FareEstimateRequest>({
    pickupLocation: '',
    destinationLocation: '',
    rideTier: 'standard',
  })

  const estimate = ref<FareEstimateResult | null>(null)
  const isCalculating = ref(false)

  async function estimateFare() {
    isCalculating.value = true
    try {
      estimate.value = await calculateFareEstimate(request)
    } finally {
      isCalculating.value = false
    }
  }

  return {
    request,
    estimate,
    isCalculating,
    estimateFare,
  }
}

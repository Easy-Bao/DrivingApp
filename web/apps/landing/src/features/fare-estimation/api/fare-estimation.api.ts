import type { FareEstimateRequest, FareEstimateResult } from '@/features/fare-estimation/types'

export async function calculateFareEstimate(
  _request: FareEstimateRequest,
): Promise<FareEstimateResult> {
  return {
    estimatedFareCents: 1500,
    estimatedDurationMinutes: 18,
    estimatedDistanceKm: 7.5,
  }
}

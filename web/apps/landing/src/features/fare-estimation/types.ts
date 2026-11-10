export interface FareEstimateRequest {
  pickupLocation: string
  destinationLocation: string
  rideTier: 'standard' | 'comfort' | 'executive'
}

export interface FareEstimateResult {
  estimatedFareCents: number
  estimatedDurationMinutes: number
  estimatedDistanceKm: number
}

export type RideTier = 'standard' | 'comfort' | 'executive'

export interface RideTierConfig {
  id: RideTier
  name: string
  shortLabel: string
  vehicleExample: string
  basePhp: number
  perKmPhp: number
  surgeCapText: string
  capacityText: string
  badgeText: string
}

export interface FareEstimateRequest {
  pickupLocation: string
  destinationLocation: string
  rideTier: RideTier
}

export interface FareEstimateResult {
  estimatedFareCents: number
  estimatedDurationMinutes: number
  estimatedDistanceKm: number
  baseFlagDownPhp: number
  suggestedBidRangePhp: {
    min: number
    max: number
  }
  surgeCapLabel: string
  corridorNote: string
}

export interface PresetCorridor {
  id: string
  label: string
  pickup: string
  destination: string
  distanceKm: number
  durationMinutes: number
  note: string
}

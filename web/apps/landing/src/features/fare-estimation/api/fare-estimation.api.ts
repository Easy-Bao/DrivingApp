import type {
  FareEstimateRequest,
  FareEstimateResult,
  PresetCorridor,
  RideTier,
  RideTierConfig,
} from '@/features/fare-estimation/types'

export const RIDE_TIER_CONFIGS: Record<RideTier, RideTierConfig> = {
  standard: {
    id: 'standard',
    name: 'Taxicle Standard',
    shortLabel: 'Standard',
    vehicleExample: 'Bajaj RE 4S / City Unit',
    basePhp: 25,
    perKmPhp: 12,
    surgeCapText: 'Max 2.0x peak cap',
    capacityText: 'Up to 4 passengers',
    badgeText: 'Everyday Poblacion trips',
  },
  comfort: {
    id: 'comfort',
    name: 'Terminal & Uphill',
    shortLabel: 'Uphill',
    vehicleExample: 'TVS King Deluxe / Maxima Z',
    basePhp: 35,
    perKmPhp: 14,
    surgeCapText: 'Max 2.5x luggage/hill cap',
    capacityText: 'Luggage + uphill torque',
    badgeText: 'Dao, Bulatok & Capitol hills',
  },
  executive: {
    id: 'executive',
    name: 'e-BaoBao Quiet',
    shortLabel: 'e-BaoBao',
    vehicleExample: 'Covered Electric Tricycle',
    basePhp: 30,
    perKmPhp: 13,
    surgeCapText: 'Max 1.8x eco cap',
    capacityText: 'Covered cabin + USB charge',
    badgeText: 'Zero tailpipe emissions',
  },
}

export const PRESET_CORRIDORS: PresetCorridor[] = [
  {
    id: 'poblacion-dao',
    label: 'Agora -> Dao',
    pickup: 'Agora Public Market, Poblacion',
    destination: 'Dao Provincial Capitol & Medical Center',
    distanceKm: 3.4,
    durationMinutes: 11,
    note: 'Includes uphill Capitol incline corridor',
  },
  {
    id: 'plaza-bulatok',
    label: 'Plaza -> Bulatok',
    pickup: 'Plaza Luzon Oval, Poblacion',
    destination: 'Integrated Bus Terminal (Bulatok)',
    distanceKm: 4.3,
    durationMinutes: 14,
    note: 'Direct inter-barangay highway corridor',
  },
  {
    id: 'tiguma-airport',
    label: 'Tiguma -> Airport',
    pickup: 'Robinsons Place Pagadian (Tiguma)',
    destination: 'Pagadian City Airport',
    distanceKm: 6.1,
    durationMinutes: 16,
    note: 'National highway + airport approach road',
  },
  {
    id: 'wharf-gaisano',
    label: 'Wharf -> Gaisano',
    pickup: 'Santiago Wharf & Pier Port',
    destination: 'Gaisano Capital Pagadian',
    distanceKm: 2.2,
    durationMinutes: 8,
    note: 'Flat coastal market and pier loop',
  },
]

interface LandmarkMetric {
  keywords: string[]
  zoneIndex: number
}

const PAGADIAN_LANDMARKS: LandmarkMetric[] = [
  { keywords: ['agora', 'market', 'poblacion'], zoneIndex: 0 },
  { keywords: ['plaza', 'luzon', 'rotunda', 'oval'], zoneIndex: 1 },
  { keywords: ['wharf', 'pier', 'santiago', 'port'], zoneIndex: 2 },
  { keywords: ['gaisano', 'mall', 'san pedro'], zoneIndex: 3 },
  { keywords: ['dao', 'capitol', 'hospital', 'medical', 'balangasan'], zoneIndex: 5 },
  { keywords: ['bulatok', 'terminal', 'bus', 'tuburan'], zoneIndex: 6 },
  { keywords: ['tiguma', 'robinson', 'robinsons'], zoneIndex: 7 },
  { keywords: ['airport', 'muricay', 'dumagoc'], zoneIndex: 9 },
]

function inferRouteMetrics(
  pickup: string,
  destination: string,
): {
  distanceKm: number
  durationMinutes: number
  note: string
} {
  const normalizedPickup = pickup.trim().toLowerCase()
  const normalizedDestination = destination.trim().toLowerCase()

  const exactPreset = PRESET_CORRIDORS.find((corridor) => {
    const p = corridor.pickup.toLowerCase()
    const d = corridor.destination.toLowerCase()
    return (
      (p === normalizedPickup && d === normalizedDestination) ||
      (d === normalizedPickup && p === normalizedDestination)
    )
  })

  if (exactPreset) {
    return {
      distanceKm: exactPreset.distanceKm,
      durationMinutes: exactPreset.durationMinutes,
      note: exactPreset.note,
    }
  }

  const fromLandmark = PAGADIAN_LANDMARKS.find((entry) =>
    entry.keywords.some((kw) => normalizedPickup.includes(kw)),
  )
  const toLandmark = PAGADIAN_LANDMARKS.find((entry) =>
    entry.keywords.some((kw) => normalizedDestination.includes(kw)),
  )

  if (fromLandmark && toLandmark) {
    const diff = Math.abs(fromLandmark.zoneIndex - toLandmark.zoneIndex)
    const distanceKm = Number(Math.max(1.5, 1.4 + diff * 0.65).toFixed(1))
    const durationMinutes = Math.max(6, Math.round(distanceKm * 2.8 + 2))
    return {
      distanceKm,
      durationMinutes,
      note: 'Estimated Pagadian City municipal road distance',
    }
  }

  const combinedChars = normalizedPickup.length + normalizedDestination.length
  const distanceKm = Number((2.1 + (combinedChars % 9) * 0.45).toFixed(1))
  const durationMinutes = Math.max(7, Math.round(distanceKm * 3.1))

  return {
    distanceKm,
    durationMinutes,
    note: 'Custom Pagadian City barangay route preview',
  }
}

export async function calculateFareEstimate(
  request: FareEstimateRequest,
): Promise<FareEstimateResult> {
  const tier = RIDE_TIER_CONFIGS[request.rideTier]
  const metrics = inferRouteMetrics(request.pickupLocation, request.destinationLocation)

  // First 1.0 km is covered by the flag-down tariff; remaining distance bills per km.
  const extraKm = Math.max(0, metrics.distanceKm - 1)
  const rawFarePhp = tier.basePhp + extraKm * tier.perKmPhp
  const roundedFloorPhp = Math.max(tier.basePhp, Math.round(rawFarePhp))

  return {
    estimatedFareCents: roundedFloorPhp * 100,
    estimatedDurationMinutes: metrics.durationMinutes,
    estimatedDistanceKm: metrics.distanceKm,
    baseFlagDownPhp: tier.basePhp,
    suggestedBidRangePhp: {
      min: roundedFloorPhp,
      max: Math.round(roundedFloorPhp * 1.25),
    },
    surgeCapLabel: tier.surgeCapText,
    corridorNote: metrics.note,
  }
}

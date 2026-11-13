import type { RideTier } from '@/features/fare-estimation/types'

export interface FleetTierSummary {
  id: string
  rideTierKey: RideTier
  name: string
  priceLabel: string
  description: string
}

export interface StepSummary {
  number: string
  title: string
  description: string
}

export interface CommissionTierItem {
  id: string
  tierName: string
  ratePercent: number
  note: string
}

export const HERO_STATS = [
  { label: 'Base Fare', value: '₱25' },
  { label: 'Live Bids', value: '90s' },
  { label: 'Payment', value: 'Cash' },
] as const

export const FLEET_TIERS: FleetTierSummary[] = [
  {
    id: 'standard',
    rideTierKey: 'standard',
    name: 'Standard',
    priceLabel: 'From ₱25',
    description: 'Bajaj RE 4S units for everyday Poblacion and barangay trips.',
  },
  {
    id: 'uphill',
    rideTierKey: 'comfort',
    name: 'Uphill',
    priceLabel: 'From ₱35',
    description: 'TVS King units suited for Dao Capitol climbs and bus luggage.',
  },
  {
    id: 'ebaobao',
    rideTierKey: 'executive',
    name: 'e-BaoBao',
    priceLabel: 'From ₱30',
    description: 'Covered electric tricycle cabin for quiet city rides.',
  },
]

export const HOW_IT_WORKS_STEPS: StepSummary[] = [
  {
    number: '01',
    title: 'Route',
    description: 'Enter pickup and drop-off to preview the upfront PHP floor.',
  },
  {
    number: '02',
    title: 'Bid',
    description: 'Choose a nearby Taxicle bid by price and arrival time.',
  },
  {
    number: '03',
    title: 'Cash',
    description: 'Arrive safely and pay the exact agreed fare in cash.',
  },
]

export const COMMISSION_TIERS: CommissionTierItem[] = [
  {
    id: 'standard',
    tierName: 'Standard',
    ratePercent: 15,
    note: 'City Taxicle units',
  },
  {
    id: 'pro',
    tierName: 'Pro',
    ratePercent: 12,
    note: '4.85+ rating tier',
  },
  {
    id: 'ebaobao',
    tierName: 'e-BaoBao',
    ratePercent: 10,
    note: 'Electric tricycle units',
  },
]

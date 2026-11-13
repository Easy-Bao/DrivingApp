import type { RideTier } from '@/features/fare-estimation/types'
import type { IconName } from '@/shared/components/UiIcon.vue'

export interface FleetServiceItem {
  id: string
  rideTierKey: RideTier
  name: string
  tagline: string
  vehicleSpec: string
  flagDownLabel: string
  rateLabel: string
  capacitySpec: string
  icon: IconName
  accentClass: string
  highlights: [string, string]
}

export interface BiddingMockBid {
  id: string
  driverName: string
  todaCode: string
  unitModel: string
  plateCode: string
  rating: string
  tripsCount: string
  etaMinutes: number
  bidPhp: number
  tierLabel: string
}

export interface BiddingStepItem {
  number: string
  title: string
  subtitle: string
  description: string
  badgeText: string
}

export interface PagadianZoneItem {
  id: string
  name: string
  shortLabel: string
  corridorType: string
  baseFlagDownPhp: number
  typicalWait: string
  sampleFarePhp: string
  landmarks: string[]
  elevationNote: string
  mapCoords: { x: number; y: number }
  svgCoords: { x: number; y: number }
  recommendedRoute: {
    pickup: string
    destination: string
    tier: RideTier
  }
}

export interface SafetyPillarItem {
  id: string
  title: string
  summary: string
  verificationCode: string
  icon: IconName
}

export interface CommissionTierItem {
  id: string
  tierName: string
  ratePercent: number
  eligibility: string
  vehicleFocus: string
  qrphMinimumPhp: number
}

export interface FaqItem {
  id: string
  audience: 'passenger' | 'driver'
  question: string
  answer: string
}

export const HERO_TRUST_METRICS = [
  { label: 'Flag-down floor', value: '₱25–₱35', detail: 'Municipal tariff upfront' },
  { label: 'Bidding window', value: '90 sec', detail: 'No street-side haggling' },
  { label: 'Fleet compliance', value: '5 Checks', detail: 'LTO · MTOP · TPL · NBI' },
] as const

export const LIVE_DISPATCH_CHANNELS = [
  { zone: 'Poblacion Agora', count: '14 units nearby' },
  { zone: 'Dao Capitol Ridge', count: '9 uphill units' },
  { zone: 'Bulatok Terminal', count: '11 units queued' },
] as const

export const FLEET_SERVICES: FleetServiceItem[] = [
  {
    id: 'taxicle-standard',
    rideTierKey: 'standard',
    name: 'Taxicle Standard',
    tagline: 'Everyday Poblacion & market rides',
    vehicleSpec: 'Bajaj RE 4S · Licensed City Unit',
    flagDownLabel: '₱25 base',
    rateLabel: '+ ₱12 / km after 1 km',
    capacitySpec: 'Up to 4 passengers · City loop',
    icon: 'taxicle',
    accentClass: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
    highlights: ['Up to 4 adult passengers', 'Cash paid upon safe drop-off'],
  },
  {
    id: 'uphill-terminal',
    rideTierKey: 'comfort',
    name: 'Uphill & Terminal',
    tagline: 'Built for Dao hills & luggage loads',
    vehicleSpec: 'TVS King Deluxe · Bajaj Maxima Z',
    flagDownLabel: '₱35 base',
    rateLabel: '+ ₱14 / km incline torque',
    capacitySpec: 'Hill torque · Luggage rack',
    icon: 'compass',
    accentClass: 'bg-amber-50 text-amber-800 ring-amber-200',
    highlights: ['Capitol, Balangasan & Bulatok', 'Reinforced rack for bus/pier bags'],
  },
  {
    id: 'ebaobao-quiet',
    rideTierKey: 'executive',
    name: 'e-BaoBao Quiet',
    tagline: 'Weather-sealed electric tricycle cabin',
    vehicleSpec: 'Electric Bao-Bao Pioneer',
    flagDownLabel: '₱30 base',
    rateLabel: '+ ₱13 / km quiet ride',
    capacitySpec: 'Covered cabin · USB power',
    icon: 'bolt',
    accentClass: 'bg-teal-50 text-teal-800 ring-teal-200',
    highlights: ['Rain curtains & USB charging', 'Lower 10% driver commission tier'],
  },
  {
    id: 'market-hop',
    rideTierKey: 'comfort',
    name: 'Market & Parcel Hop',
    tagline: 'Same-hour barangay errands & grocers',
    vehicleSpec: 'Verified TODA Utility Taxicle',
    flagDownLabel: '₱35 base',
    rateLabel: 'PIN-verified recipient drop-off',
    capacitySpec: 'Market crates · GPS share link',
    icon: 'package',
    accentClass: 'bg-slate-100 text-slate-800 ring-slate-200',
    highlights: ['Agora Market & mall pickups', 'Live GPS share link for sender'],
  },
]

export const BIDDING_STEPS: BiddingStepItem[] = [
  {
    number: '01',
    title: 'Lock the municipal fare floor first',
    subtitle: 'Known Pagadian baseline',
    description:
      'Pick your barangay landmark and drop-off point. EasyRide calculates the PHP fare floor and surge cap upfront so both rider and driver start from the same fair number.',
    badgeText: 'Agora Market -> Dao Capitol · Floor ₱54',
  },
  {
    number: '02',
    title: 'Compare live driver bids inside 90 seconds',
    subtitle: 'Full unit & ETA transparency',
    description:
      'Nearby online Taxicles with verified MTOP and active QRPh wallet balance send real bids. Sort by lowest PHP fare or fastest pickup ETA before choosing.',
    badgeText: '3 live bids · Tap any bid card to inspect',
  },
  {
    number: '03',
    title: 'Accept, share GPS, pay exact cash on arrival',
    subtitle: 'Tracked door-to-door',
    description:
      'Once you accept a bid, your family can follow the live trip link. Your agreed fare never climbs mid-ride, and one-tap SOS stays pinned throughout the trip.',
    badgeText: 'MTOP Plate Verified · Cash ₱55 Locked',
  },
]

export const BIDDING_MOCK_BIDS: BiddingMockBid[] = [
  {
    id: 'bid-danilo',
    driverName: 'Danilo R.',
    todaCode: 'POBLACION-04',
    unitModel: 'Bajaj RE 4S',
    plateCode: 'ZDS-418M',
    rating: '4.94',
    tripsCount: '1,240 trips',
    etaMinutes: 2,
    bidPhp: 55,
    tierLabel: 'Fastest pickup',
  },
  {
    id: 'bid-carlo',
    driverName: 'Carlo M.',
    todaCode: 'DAO-TODA-11',
    unitModel: 'Electric Bao-Bao',
    plateCode: 'EV-092P',
    rating: '4.97',
    tripsCount: '890 trips',
    etaMinutes: 3,
    bidPhp: 58,
    tierLabel: 'Covered cabin',
  },
  {
    id: 'bid-ramon',
    driverName: 'Ramon T.',
    todaCode: 'BULATOK-07',
    unitModel: 'TVS King Deluxe',
    plateCode: 'ZDS-773B',
    rating: '4.88',
    tripsCount: '2,110 trips',
    etaMinutes: 5,
    bidPhp: 60,
    tierLabel: 'Extra rack space',
  },
]

export const PAGADIAN_ZONES: PagadianZoneItem[] = [
  {
    id: 'poblacion-agora',
    name: 'Poblacion & Agora Market',
    shortLabel: 'Poblacion',
    corridorType: 'Core downtown loop',
    baseFlagDownPhp: 25,
    typicalWait: '1–3 min',
    sampleFarePhp: '₱25–₱45',
    landmarks: ['Agora Public Market', 'Plaza Luzon Oval', 'Pagadian City Hall', 'San Jose'],
    elevationNote: 'Sea-level coastal avenues & dense TODA staging points',
    mapCoords: { x: 46, y: 66 },
    svgCoords: { x: 276, y: 211 },
    recommendedRoute: {
      pickup: 'Santiago Wharf & Pier Port',
      destination: 'Agora Public Market, Poblacion',
      tier: 'standard',
    },
  },
  {
    id: 'dao-capitol',
    name: 'Dao Capitol & Hospital Ridge',
    shortLabel: 'Dao Ridge',
    corridorType: 'Uphill incline corridor',
    baseFlagDownPhp: 35,
    typicalWait: '2–5 min',
    sampleFarePhp: '₱50–₱75',
    landmarks: [
      'Provincial Capitol Complex',
      'Zamboanga del Sur Medical Center',
      'Balangasan',
      'National Agencies Hub',
    ],
    elevationNote: '+115m incline ridge · Bajaj Maxima Z & TVS King dispatch priority',
    mapCoords: { x: 42, y: 26 },
    svgCoords: { x: 252, y: 83 },
    recommendedRoute: {
      pickup: 'Agora Public Market, Poblacion',
      destination: 'Dao Provincial Capitol & Medical Center',
      tier: 'comfort',
    },
  },
  {
    id: 'bulatok-tiguma',
    name: 'Bulatok Terminal & Tiguma',
    shortLabel: 'Bulatok / Tiguma',
    corridorType: 'Inter-town & mall artery',
    baseFlagDownPhp: 35,
    typicalWait: '2–4 min',
    sampleFarePhp: '₱45–₱85',
    landmarks: [
      'Integrated Bus Terminal (Bulatok)',
      'Robinsons Place Pagadian',
      'Gaisano Capital',
      'Tuburan & San Pedro',
    ],
    elevationNote: 'Dedicated arrival bay staging for regional bus transfers',
    mapCoords: { x: 18, y: 45 },
    svgCoords: { x: 108, y: 144 },
    recommendedRoute: {
      pickup: 'Plaza Luzon Oval, Poblacion',
      destination: 'Integrated Bus Terminal (Bulatok)',
      tier: 'comfort',
    },
  },
  {
    id: 'airport-wharf',
    name: 'Airport & Santiago Wharf',
    shortLabel: 'Airport & Pier',
    corridorType: 'Sea-to-sky transfer corridor',
    baseFlagDownPhp: 35,
    typicalWait: '3–6 min',
    sampleFarePhp: '₱40–₱110',
    landmarks: ['Pagadian City Airport', 'Muricay Junction', 'Santiago Wharf Pier', 'White Beach'],
    elevationNote: 'Luggage-friendly racks for ferry & morning flight schedules',
    mapCoords: { x: 80, y: 38 },
    svgCoords: { x: 480, y: 122 },
    recommendedRoute: {
      pickup: 'Robinsons Place Pagadian (Tiguma)',
      destination: 'Pagadian City Airport',
      tier: 'executive',
    },
  },
]

export const SAFETY_PILLARS: SafetyPillarItem[] = [
  {
    id: 'lto-mtop',
    title: 'MTOP & TODA Franchise Gate',
    summary:
      'Every listed unit matches its municipal MTOP body number and active TODA endorsement in Pagadian City.',
    verificationCode: 'GATE 01 · MTOP / TODA',
    icon: 'shield-check',
  },
  {
    id: 'driver-clearance',
    title: 'Pro License, NBI & PNP Checked',
    summary:
      'Admin operations audit LTO Professional Driver licenses, LTO OR/CR, compulsory TPL insurance, and clearances before go-live.',
    verificationCode: 'GATE 02 · LTO + CLEARANCE',
    icon: 'check-circle',
  },
  {
    id: 'live-share',
    title: 'Live Trip Link & Plate Lock',
    summary:
      'Share real-time route progress and confirmed plate number with family via SMS or chat from pickup to drop-off.',
    verificationCode: 'GATE 03 · LIVE TELEMETRY',
    icon: 'navigation',
  },
  {
    id: 'sos-desk',
    title: 'One-Tap SOS & Local Escalation',
    summary:
      'In-trip emergency trigger alerts EasyRide Ops Desk and surfaces direct Pagadian CDRRMO (062-925-0911) and 911 dialers.',
    verificationCode: 'GATE 04 · 24/7 SOS DESK',
    icon: 'alert',
  },
]

export const COMMISSION_TIERS: CommissionTierItem[] = [
  {
    id: 'standard',
    tierName: 'Standard Taxicle',
    ratePercent: 15,
    eligibility: 'Newly verified LTO + MTOP Taxicle & TukTuk units',
    vehicleFocus: 'Bajaj RE 4S / City Fleet',
    qrphMinimumPhp: 50,
  },
  {
    id: 'pro',
    tierName: 'Pro Rated Driver',
    ratePercent: 12,
    eligibility: '4.85★+ rolling rating & >= 95% trip completion',
    vehicleFocus: 'TVS King / Priority Incline',
    qrphMinimumPhp: 50,
  },
  {
    id: 'ebaobao',
    tierName: 'e-BaoBao Pioneer',
    ratePercent: 10,
    eligibility: 'Zero-emission electric tricolor units with verified charging setup',
    vehicleFocus: 'Covered Electric Tricycle',
    qrphMinimumPhp: 50,
  },
]

export const FAQ_ITEMS: FaqItem[] = [
  {
    id: 'faq-floor-pricing',
    audience: 'passenger',
    question: 'How does EasyRide calculate the Taxicle fare floor in Pagadian City?',
    answer:
      'Every estimate starts from our transparent municipal baseline (₱25 flag-down for Poblacion Standard Taxicles or ₱35 for Uphill/Terminal units) plus ₱12–₱14 per kilometer beyond the first kilometer, capped between 1.0x and 2.5x during heavy rain or rush hour.',
  },
  {
    id: 'faq-bidding',
    audience: 'passenger',
    question: 'Do I have to accept the first driver bid?',
    answer:
      'No. During the 90-second live bidding window you can compare multiple verified drivers side by side — checking their PHP bid, pickup ETA in minutes, star rating, TODA association badge, and Taxicle unit model before tapping Accept.',
  },
  {
    id: 'faq-payment',
    audience: 'passenger',
    question: 'How do passengers pay for trips right now?',
    answer:
      'Passengers pay exact cash to the driver upon safe arrival at the drop-off point, matching the locked accepted bid. Digital receipts remain recorded inside trip history for fare transparency.',
  },
  {
    id: 'faq-qrph',
    audience: 'driver',
    question: 'How does the driver prepaid commission wallet work with Company QRPh?',
    answer:
      'Because passengers pay trips in cash, drivers keep at least ₱50.00 in their EasyRide wallet to stay dispatch-eligible. Top up anytime via GCash, Maya, BDO, or BPI InstaPay using Company QRPh, and only 10%–15% per completed ride is deducted automatically.',
  },
  {
    id: 'faq-documents',
    audience: 'driver',
    question: 'Which documents do Taxicle drivers need to get verified in Pagadian?',
    answer:
      'Upload clear photos of your LTO Professional Driver License, LTO OR/CR, valid Pagadian MTOP Franchise, TODA Endorsement, Compulsory Third-Party Liability (TPL) Insurance, and NBI/PNP Clearances. Expiry reminders alert you before renewals lapse.',
  },
  {
    id: 'faq-incline',
    audience: 'driver',
    question: 'Are steeper routes like Dao Capitol or Balangasan priced fairly for fuel?',
    answer:
      'Yes. The Uphill & Terminal tier carries a higher ₱35 base floor and ₱14/km distance component, and during bidding you can submit an exact PHP counter-bid within the surge cap that reflects hill gradient, passengers, or bulky luggage.',
  },
]

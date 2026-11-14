export type DashboardTimeframe = 'today' | '7d' | '30d'
export type ChartMetric = 'trips' | 'revenue'

export type BookingSliceKey = 'broadcast' | 'targeted'
export type StatusOutcomeKey = 'completed' | 'in_progress' | 'dispatching' | 'cancelled'
export type DashboardKpiKey = 'rides' | 'drivers' | 'revenue' | 'completion'

export interface VolumeBucket {
  label: string
  trips: number
  revenuePhp: number
}

export interface BookingSlice {
  key: BookingSliceKey
  label: string
  count: number
  percent: number
}

export interface StatusMetric {
  key: StatusOutcomeKey
  label: string
  count: number
  share: string
}

export interface DashboardDataset {
  comparisonLabel: string
  activeRides: number
  ridesDelta: string
  activeDrivers: number
  driverDelta: string
  completionRate: string
  completionDelta: string
  revenueDelta: string
  series: readonly VolumeBucket[]
  bookingMix: readonly BookingSlice[]
  statusMix: readonly StatusMetric[]
}

export interface DashboardKpi {
  key: DashboardKpiKey
  label: string
  value: string
  change: string
  comparisonLabel: string
}

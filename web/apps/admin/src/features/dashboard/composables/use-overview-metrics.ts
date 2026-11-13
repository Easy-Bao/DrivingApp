import { computed, type Ref } from 'vue'
import { formatPhp } from '@/shared/utils/format'

export type DashboardTimeframe = 'today' | '7d' | '30d'

export interface DashboardKpi {
  label: string
  value: string
  change: string
  comparisonLabel: string
  icon: string
}

export interface VolumeBucket {
  label: string
  trips: number
  revenuePhp: number
}

export interface BreakdownSlice {
  label: string
  count: number
  percent: number
  colorHex: string
  barClass: string
}

export interface StatusMetric {
  label: string
  count: number
  share: string
  barClass: string
}

interface TimeframeDataset {
  comparisonLabel: string
  activeDrivers: number
  driverDelta: string
  activeRides: number
  ridesDelta: string
  completionRate: string
  completionDelta: string
  series: VolumeBucket[]
  bookingMix: BreakdownSlice[]
  statusMix: StatusMetric[]
}

const datasets: Record<DashboardTimeframe, TimeframeDataset> = {
  today: {
    comparisonLabel: 'vs yesterday',
    activeRides: 142,
    ridesDelta: '+14%',
    activeDrivers: 318,
    driverDelta: '+6%',
    completionRate: '96.4%',
    completionDelta: '+0.8%',
    series: [
      { label: '00–03', trips: 28, revenuePhp: 2100 },
      { label: '03–06', trips: 34, revenuePhp: 2380 },
      { label: '06–09', trips: 146, revenuePhp: 8030 },
      { label: '09–12', trips: 118, revenuePhp: 7670 },
      { label: '12–15', trips: 124, revenuePhp: 8680 },
      { label: '15–18', trips: 168, revenuePhp: 9240 },
      { label: '18–21', trips: 132, revenuePhp: 9900 },
      { label: '21–24', trips: 54, revenuePhp: 4050 },
    ],
    bookingMix: [
      {
        label: 'Open Broadcast',
        count: 555,
        percent: 69,
        colorHex: '#171717',
        barClass: 'bg-neutral-900',
      },
      {
        label: 'Chosen Driver',
        count: 249,
        percent: 31,
        colorHex: '#059669',
        barClass: 'bg-emerald-600',
      },
    ],
    statusMix: [
      { label: 'Completed', count: 775, share: '96.4%', barClass: 'bg-emerald-600' },
      { label: 'In Progress', count: 14, share: '1.7%', barClass: 'bg-neutral-900' },
      { label: 'Dispatching', count: 7, share: '0.9%', barClass: 'bg-amber-500' },
      { label: 'Cancelled', count: 8, share: '1.0%', barClass: 'bg-rose-500' },
    ],
  },
  '7d': {
    comparisonLabel: 'vs prior 7 days',
    activeRides: 5420,
    ridesDelta: '+9%',
    activeDrivers: 342,
    driverDelta: '+4%',
    completionRate: '95.8%',
    completionDelta: '+0.5%',
    series: [
      { label: 'Mon', trips: 710, revenuePhp: 39050 },
      { label: 'Tue', trips: 760, revenuePhp: 41800 },
      { label: 'Wed', trips: 790, revenuePhp: 47400 },
      { label: 'Thu', trips: 815, revenuePhp: 52975 },
      { label: 'Fri', trips: 895, revenuePhp: 53700 },
      { label: 'Sat', trips: 820, revenuePhp: 59040 },
      { label: 'Sun', trips: 630, revenuePhp: 46620 },
    ],
    bookingMix: [
      {
        label: 'Open Broadcast',
        count: 3523,
        percent: 65,
        colorHex: '#171717',
        barClass: 'bg-neutral-900',
      },
      {
        label: 'Chosen Driver',
        count: 1897,
        percent: 35,
        colorHex: '#059669',
        barClass: 'bg-emerald-600',
      },
    ],
    statusMix: [
      { label: 'Completed', count: 5192, share: '95.8%', barClass: 'bg-emerald-600' },
      { label: 'In Progress', count: 70, share: '1.3%', barClass: 'bg-neutral-900' },
      { label: 'Dispatching', count: 44, share: '0.8%', barClass: 'bg-amber-500' },
      { label: 'Cancelled', count: 114, share: '2.1%', barClass: 'bg-rose-500' },
    ],
  },
  '30d': {
    comparisonLabel: 'vs prior 30 days',
    activeRides: 22840,
    ridesDelta: '+18%',
    activeDrivers: 364,
    driverDelta: '+8%',
    completionRate: '96.1%',
    completionDelta: '+1.1%',
    series: [
      { label: 'Week 1', trips: 5240, revenuePhp: 303920 },
      { label: 'Week 2', trips: 5610, revenuePhp: 336600 },
      { label: 'Week 3', trips: 5890, revenuePhp: 388740 },
      { label: 'Week 4', trips: 6100, revenuePhp: 366000 },
    ],
    bookingMix: [
      {
        label: 'Open Broadcast',
        count: 14161,
        percent: 62,
        colorHex: '#171717',
        barClass: 'bg-neutral-900',
      },
      {
        label: 'Chosen Driver',
        count: 8679,
        percent: 38,
        colorHex: '#059669',
        barClass: 'bg-emerald-600',
      },
    ],
    statusMix: [
      { label: 'Completed', count: 21949, share: '96.1%', barClass: 'bg-emerald-600' },
      { label: 'In Progress', count: 142, share: '0.6%', barClass: 'bg-neutral-900' },
      { label: 'Dispatching', count: 58, share: '0.3%', barClass: 'bg-amber-500' },
      { label: 'Cancelled', count: 691, share: '3.0%', barClass: 'bg-rose-500' },
    ],
  },
}

export function useOverviewMetrics(timeframe: Ref<DashboardTimeframe>) {
  const activeDataset = computed(() => datasets[timeframe.value])

  const totalTrips = computed(() =>
    activeDataset.value.series.reduce((sum, bucket) => sum + bucket.trips, 0),
  )

  const totalRevenuePhp = computed(() =>
    activeDataset.value.series.reduce((sum, bucket) => sum + bucket.revenuePhp, 0),
  )

  const kpis = computed<DashboardKpi[]>(() => {
    const data = activeDataset.value
    const isToday = timeframe.value === 'today'
    return [
      {
        label: isToday ? 'Active Rides' : 'Total Trips',
        value: data.activeRides.toLocaleString(),
        change: data.ridesDelta,
        comparisonLabel: data.comparisonLabel,
        icon: 'lucide:navigation',
      },
      {
        label: 'Online Drivers',
        value: data.activeDrivers.toLocaleString(),
        change: data.driverDelta,
        comparisonLabel: data.comparisonLabel,
        icon: 'lucide:users',
      },
      {
        label: 'Trip Revenue',
        value: formatPhp(totalRevenuePhp.value),
        change: isToday ? '+21%' : timeframe.value === '7d' ? '+12%' : '+19%',
        comparisonLabel: data.comparisonLabel,
        icon: 'lucide:banknote',
      },
      {
        label: 'Completion Rate',
        value: data.completionRate,
        change: data.completionDelta,
        comparisonLabel: data.comparisonLabel,
        icon: 'lucide:check-circle-2',
      },
    ]
  })

  return {
    activeDataset,
    totalTrips,
    totalRevenuePhp,
    kpis,
  }
}

import { computed, type Ref } from 'vue'
import { DASHBOARD_DATASETS } from '@/features/dashboard/data/overview.seed'
import type { DashboardKpi, DashboardTimeframe } from '@/features/dashboard/types'
import { formatCentavos } from '@/shared'

export function useOverviewMetrics(timeframe: Ref<DashboardTimeframe>) {
  const activeDataset = computed(() => DASHBOARD_DATASETS[timeframe.value])

  const totalTrips = computed(() =>
    activeDataset.value.series.reduce((sum, bucket) => sum + bucket.trips, 0),
  )

  const totalRevenueCentavos = computed(() =>
    activeDataset.value.series.reduce(
      (sum, bucket) => sum + Math.round(bucket.revenuePhp * 100),
      0,
    ),
  )

  const totalRevenuePhp = computed(() => totalRevenueCentavos.value / 100)

  const kpis = computed<DashboardKpi[]>(() => {
    const data = activeDataset.value
    const isToday = timeframe.value === 'today'
    return [
      {
        key: 'rides',
        label: isToday ? 'Active Rides' : 'Total Trips',
        value: data.activeRides.toLocaleString(),
        change: data.ridesDelta,
        comparisonLabel: data.comparisonLabel,
      },
      {
        key: 'drivers',
        label: 'Online Drivers',
        value: data.activeDrivers.toLocaleString(),
        change: data.driverDelta,
        comparisonLabel: data.comparisonLabel,
      },
      {
        key: 'revenue',
        label: 'Trip Revenue',
        value: formatCentavos(totalRevenueCentavos.value),
        change: data.revenueDelta,
        comparisonLabel: data.comparisonLabel,
      },
      {
        key: 'completion',
        label: 'Completion Rate',
        value: data.completionRate,
        change: data.completionDelta,
        comparisonLabel: data.comparisonLabel,
      },
    ]
  })

  return {
    activeDataset,
    totalTrips,
    totalRevenueCentavos,
    totalRevenuePhp,
    kpis,
  }
}

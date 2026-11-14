export type {
  BookingSlice,
  BookingSliceKey,
  ChartMetric,
  DashboardDataset,
  DashboardKpi,
  DashboardKpiKey,
  DashboardTimeframe,
  StatusMetric,
  StatusOutcomeKey,
  VolumeBucket,
} from '@/features/dashboard/types'

export {
  buildBarSlots,
  buildDonutSegments,
  buildFlatBaselinePath,
  buildGridTicks,
  buildTrendPath,
  computeNiceMaxValue,
  findPeakBucketIndex,
  type BarSlot,
  type DonutSegment,
  type GridTick,
  type PlotBounds,
} from '@/features/dashboard/domain/chart-geometry'

export { useOverviewMetrics } from '@/features/dashboard/composables/use-overview-metrics'

export { default as FleetDistributionCard } from '@/features/dashboard/components/FleetDistributionCard.vue'
export { default as TripVolumeChart } from '@/features/dashboard/components/TripVolumeChart.vue'

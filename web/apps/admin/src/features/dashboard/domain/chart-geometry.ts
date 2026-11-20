import type { BookingSlice, ChartMetric, VolumeBucket } from '@/features/dashboard/types'

export interface DonutSegment extends BookingSlice {
  dashArray: string
  dashOffset: number
}

export interface GridTick {
  index: number
  y: number
  label: string
}

export interface BarSlot extends VolumeBucket {
  index: number
  x: number
  y: number
  barWidth: number
  barHeight: number
  scaleY: number
  centerX: number
  isHighlighted: boolean
}

export interface PlotBounds {
  padLeft: number
  padTop: number
  plotWidth: number
  plotHeight: number
}

export function buildDonutSegments(
  slices: readonly BookingSlice[],
  circumference: number,
): DonutSegment[] {
  if (slices.length === 0) return []
  const total = slices.reduce((sum, slice) => sum + Math.max(0, slice.count), 0)
  if (total <= 0) return []

  let accumulatedLength = 0
  return slices.map((slice) => {
    const segmentLength = (Math.max(0, slice.count) / total) * circumference
    const remainder = Math.max(0, circumference - segmentLength)
    const dashOffset = Number((-accumulatedLength).toFixed(2))
    accumulatedLength += segmentLength

    return {
      ...slice,
      dashArray: `${segmentLength.toFixed(2)} ${remainder.toFixed(2)}`,
      dashOffset: dashOffset === 0 ? 0 : dashOffset,
    }
  })
}

export function findPeakBucketIndex(series: readonly VolumeBucket[], metric: ChartMetric): number {
  if (series.length === 0) return 0
  let bestIndex = 0
  let bestValue = metric === 'trips' ? series[0]!.trips : series[0]!.revenuePhp

  for (let index = 1; index < series.length; index++) {
    const candidate = metric === 'trips' ? series[index]!.trips : series[index]!.revenuePhp
    if (candidate > bestValue) {
      bestValue = candidate
      bestIndex = index
    }
  }
  return bestIndex
}

export function computeNiceMaxValue(series: readonly VolumeBucket[], metric: ChartMetric): number {
  const values = series.map((bucket) => (metric === 'trips' ? bucket.trips : bucket.revenuePhp))
  const rawMax = Math.max(1, ...values)
  const magnitude = Math.pow(10, Math.floor(Math.log10(rawMax)))
  return Math.ceil((rawMax * 1.15) / magnitude) * magnitude
}

export function buildGridTicks(
  maxValue: number,
  metric: ChartMetric,
  padTop: number,
  plotHeight: number,
): GridTick[] {
  return [0, 0.25, 0.5, 0.75, 1].map((ratio, index) => {
    const value = Math.round(maxValue * ratio)
    const y = padTop + plotHeight * (1 - ratio)
    const label =
      metric === 'revenue'
        ? value >= 1000
          ? `₱${Math.round(value / 1000)}k`
          : `₱${value}`
        : value >= 1000
          ? `${(value / 1000).toFixed(1)}k`
          : String(value)
    return { index, y, label }
  })
}

export function buildBarSlots(
  series: readonly VolumeBucket[],
  metric: ChartMetric,
  highlightedIndex: number,
  maxValue: number,
  bounds: PlotBounds,
): BarSlot[] {
  const count = Math.max(1, series.length)
  const step = bounds.plotWidth / count
  const barWidth = Math.min(44, step * 0.56)
  const safeMax = Math.max(1, maxValue)

  return series.map((bucket, index) => {
    const metricValue = metric === 'trips' ? bucket.trips : bucket.revenuePhp
    const ratio = Math.max(0, metricValue / safeMax)
    const scaleY = Math.max(2 / bounds.plotHeight, ratio)
    const barHeight = scaleY * bounds.plotHeight
    const x = bounds.padLeft + step * index + (step - barWidth) / 2
    const y = bounds.padTop + bounds.plotHeight - barHeight
    const centerX = x + barWidth / 2

    return {
      ...bucket,
      index,
      x,
      y,
      barWidth,
      barHeight,
      scaleY,
      centerX,
      isHighlighted: index === highlightedIndex,
    }
  })
}

export function buildTrendPath(slots: readonly BarSlot[]): string {
  return slots
    .map((slot, index) => `${index === 0 ? 'M' : 'L'} ${slot.centerX} ${slot.y}`)
    .join(' ')
}

export function buildFlatBaselinePath(slots: readonly BarSlot[], baselineY: number): string {
  return slots
    .map((slot, index) => `${index === 0 ? 'M' : 'L'} ${slot.centerX} ${baselineY}`)
    .join(' ')
}

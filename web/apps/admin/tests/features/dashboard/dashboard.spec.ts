import { ref } from 'vue'
import { describe, expect, it } from 'vitest'
import {
  buildBarSlots,
  buildDonutSegments,
  buildGridTicks,
  buildTrendPath,
  computeNiceMaxValue,
  findPeakBucketIndex,
  useOverviewMetrics,
  type DashboardTimeframe,
} from '@/features/dashboard'

describe('dashboard geometry & useOverviewMetrics', () => {
  it('computes O(n) contiguous donut segments summing to full circumference', () => {
    const circumference = 2 * Math.PI * 36
    const segments = buildDonutSegments(
      [
        { key: 'broadcast', label: 'Open Broadcast', count: 60, percent: 60 },
        { key: 'targeted', label: 'Chosen Driver', count: 40, percent: 40 },
      ],
      circumference,
    )

    expect(segments).toHaveLength(2)
    expect(segments[0]!.dashOffset).toBe(0)
    const seg0Len = (60 / 100) * circumference
    expect(segments[1]!.dashOffset).toBeCloseTo(-seg0Len, 1)
    expect(buildDonutSegments([], circumference)).toEqual([])
  })

  it('computes volume chart geometry helpers cleanly', () => {
    const series = [
      { label: '06–09', trips: 140, revenuePhp: 7700 },
      { label: '15–18', trips: 260, revenuePhp: 15600 },
    ]
    expect(findPeakBucketIndex(series, 'trips')).toBe(1)
    expect(findPeakBucketIndex([], 'revenue')).toBe(0)
    expect(computeNiceMaxValue(series, 'trips')).toBeGreaterThanOrEqual(260)

    const ticks = buildGridTicks(300, 'revenue', 16, 148)
    expect(ticks).toHaveLength(5)
    expect(ticks[4]!.label).toContain('₱')

    const slots = buildBarSlots(series, 'trips', 1, 300, {
      padLeft: 52,
      padTop: 16,
      plotWidth: 532,
      plotHeight: 148,
    })
    expect(slots).toHaveLength(2)
    expect(slots[1]!.isHighlighted).toBe(true)
    expect(buildTrendPath(slots)).toMatch(/^M .+ L .+$/)
  })

  it('switches KPI metrics by timeframe with integer centavo totals and pure domain slices', () => {
    const timeframe = ref<DashboardTimeframe>('today')
    const { activeDataset, totalTrips, totalRevenueCentavos, kpis } = useOverviewMetrics(timeframe)

    expect(totalTrips.value).toBe(1070)
    expect(totalRevenueCentavos.value).toBe(6419500)
    expect(kpis.value[0]!.label).toBe('Active Rides')
    expect(activeDataset.value.bookingMix[0]).not.toHaveProperty('barClass')
    expect(activeDataset.value.bookingMix[0]).not.toHaveProperty('colorHex')
    expect(kpis.value[0]).not.toHaveProperty('icon')

    timeframe.value = '7d'
    expect(kpis.value[0]!.label).toBe('Total Trips')
    expect(totalTrips.value).toBe(5420)
    const statusSum = activeDataset.value.statusMix.reduce((sum, item) => sum + item.count, 0)
    expect(statusSum).toBe(5420)
  })
})

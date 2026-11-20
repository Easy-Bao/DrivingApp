<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { MotionConfig, motion } from 'motion-v'
import {
  buildBarSlots,
  buildFlatBaselinePath,
  buildGridTicks,
  buildTrendPath,
  computeNiceMaxValue,
  findPeakBucketIndex,
} from '@/features/dashboard/domain/chart-geometry'
import type { ChartMetric, VolumeBucket } from '@/features/dashboard/types'
import { SegmentedToggle, formatPhp } from '@/shared'

const props = defineProps<{
  series: readonly VolumeBucket[]
  totalTrips: number
  totalRevenuePhp: number
}>()

const activeMetric = ref<ChartMetric>('trips')
const hoveredIndex = ref<number | null>(null)
const pinnedIndex = ref<number | null>(null)

const metricOptions = [
  { label: 'Trips', value: 'trips' },
  { label: 'Trip Fare', value: 'revenue' },
] as const

watch(
  () => props.series,
  () => {
    hoveredIndex.value = null
    pinnedIndex.value = null
  },
)

const peakIndex = computed(() => findPeakBucketIndex(props.series, activeMetric.value))
const activeSelectionIndex = computed(() => hoveredIndex.value ?? pinnedIndex.value)
const highlightedIndex = computed(() => activeSelectionIndex.value ?? peakIndex.value)
const highlightedBucket = computed(() => props.series[highlightedIndex.value] ?? null)

function togglePinnedBucket(index: number) {
  pinnedIndex.value = pinnedIndex.value === index ? null : index
}

function getBucketAriaLabel(index: number): string {
  const bucket = props.series[index]
  if (!bucket) return ''
  return `${bucket.label}: ${bucket.trips.toLocaleString()} trips, ${formatPhp(bucket.revenuePhp)}`
}

const averageTripFare = computed(() =>
  props.totalTrips > 0 ? props.totalRevenuePhp / props.totalTrips : 0,
)

const seriesKey = computed(() => props.series.map((bucket) => bucket.label).join('|'))

const chartHeight = 190
const chartWidth = 600
const padLeft = 52
const padRight = 16
const padTop = 16
const padBottom = 26
const plotWidth = chartWidth - padLeft - padRight
const plotHeight = chartHeight - padTop - padBottom
const baselineY = padTop + plotHeight

const maxValue = computed(() => computeNiceMaxValue(props.series, activeMetric.value))

const gridTicks = computed(() =>
  buildGridTicks(maxValue.value, activeMetric.value, padTop, plotHeight),
)

const styledBarSlots = computed(() => {
  const isTrips = activeMetric.value === 'trips'
  const slots = buildBarSlots(
    props.series,
    activeMetric.value,
    highlightedIndex.value,
    maxValue.value,
    { padLeft, padTop, plotWidth, plotHeight },
  )

  return slots.map((slot) => ({
    ...slot,
    barFill: slot.isHighlighted
      ? isTrips
        ? '#171717'
        : '#059669'
      : isTrips
        ? '#d4d4d4'
        : '#a7f3d0',
    dotFill: slot.isHighlighted
      ? isTrips
        ? '#059669'
        : '#171717'
      : isTrips
        ? '#10b981'
        : '#059669',
  }))
})

const trendPathD = computed(() => buildTrendPath(styledBarSlots.value))
const flatBaselinePathD = computed(() => buildFlatBaselinePath(styledBarSlots.value, baselineY))
const trendStrokeColor = computed(() => (activeMetric.value === 'trips' ? '#10b981' : '#171717'))
</script>

<template>
  <section class="bg-white border border-neutral-200 p-5 flex flex-col gap-4">
    <MotionConfig reducedMotion="user">
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div>
          <h2 class="font-semibold text-sm text-neutral-900">Trip Volume &amp; Revenue Trend</h2>
          <p class="text-xs text-neutral-500 mt-0.5 tabular-nums">
            Total {{ totalTrips.toLocaleString() }} trips · {{ formatPhp(totalRevenuePhp) }} · Avg
            {{ formatPhp(averageTripFare) }}
          </p>
        </div>

        <SegmentedToggle
          v-model="activeMetric"
          aria-label="Chart metric"
          :options="metricOptions"
        />
      </div>

      <motion.div
        v-if="highlightedBucket"
        :key="`${seriesKey}-${highlightedBucket.label}-${activeMetric}`"
        :initial="{ opacity: 0.65, y: 2 }"
        :animate="{ opacity: 1, y: 0 }"
        :transition="{ duration: 0.16, ease: [0.16, 1, 0.3, 1] }"
        class="flex flex-wrap items-center justify-between gap-2 px-3 py-2 bg-neutral-50 border border-neutral-200 text-xs tabular-nums"
      >
        <span class="font-semibold text-neutral-900">
          {{ activeSelectionIndex !== null ? 'Selected' : 'Peak Window' }}:
          {{ highlightedBucket.label }}
        </span>
        <div class="flex items-center gap-4 font-mono">
          <span
            :class="
              activeMetric === 'trips' ? 'font-semibold text-neutral-900' : 'text-neutral-500'
            "
          >
            {{ highlightedBucket.trips.toLocaleString() }} trips
          </span>
          <span
            :class="
              activeMetric === 'revenue' ? 'font-semibold text-emerald-700' : 'text-neutral-600'
            "
          >
            {{ formatPhp(highlightedBucket.revenuePhp) }}
          </span>
        </div>
      </motion.div>

      <div class="w-full overflow-x-auto">
        <svg
          :viewBox="`0 0 ${chartWidth} ${chartHeight}`"
          class="w-full min-w-[380px] h-48 select-none"
          role="img"
          aria-label="Trip volume and fare revenue chart"
        >
          <g v-for="tick in gridTicks" :key="tick.index">
            <line
              :x1="padLeft"
              :x2="chartWidth - padRight"
              :y1="tick.y"
              :y2="tick.y"
              stroke="#f0f0f0"
              stroke-width="1"
            />
            <motion.text
              :key="`tick-${seriesKey}-${activeMetric}-${tick.index}`"
              :x="padLeft - 8"
              :y="tick.y + 3"
              text-anchor="end"
              fill="#737373"
              font-size="10"
              font-family="monospace"
              :initial="{ opacity: 0.25 }"
              :animate="{ opacity: 1 }"
              :transition="{ duration: 0.2 }"
            >
              {{ tick.label }}
            </motion.text>
          </g>

          <motion.path
            v-if="styledBarSlots.length > 1"
            :key="`trend-${seriesKey}`"
            :initial="{ d: flatBaselinePathD, opacity: 0 }"
            :animate="{ d: trendPathD, opacity: 1, stroke: trendStrokeColor }"
            :transition="{
              d: { duration: 0.42, ease: [0.16, 1, 0.3, 1] },
              opacity: { duration: 0.25 },
              stroke: { duration: 0.2 },
            }"
            fill="none"
            stroke-width="1.5"
            stroke-dasharray="3 3"
          />

          <g
            v-for="slot in styledBarSlots"
            :key="`${seriesKey}-${slot.label}`"
            role="button"
            tabindex="0"
            :aria-pressed="pinnedIndex === slot.index"
            :aria-label="getBucketAriaLabel(slot.index)"
            class="cursor-pointer"
            @mouseenter="hoveredIndex = slot.index"
            @mouseleave="hoveredIndex = null"
            @focus="hoveredIndex = slot.index"
            @blur="hoveredIndex = null"
            @click="togglePinnedBucket(slot.index)"
            @keydown.enter.prevent="togglePinnedBucket(slot.index)"
            @keydown.space.prevent="togglePinnedBucket(slot.index)"
          >
            <motion.rect
              :key="`bar-${seriesKey}-${slot.label}`"
              :x="slot.x"
              :y="padTop"
              :width="slot.barWidth"
              :height="plotHeight"
              :style="{ transformOrigin: '50% 100%', transformBox: 'fill-box' }"
              :initial="{ scaleY: 0, opacity: 0.2 }"
              :animate="{ scaleY: slot.scaleY, opacity: 1, fill: slot.barFill }"
              :transition="{
                scaleY: { duration: 0.42, delay: slot.index * 0.025, ease: [0.16, 1, 0.3, 1] },
                opacity: { duration: 0.25, delay: slot.index * 0.025 },
                fill: { duration: 0.18 },
              }"
            />
            <motion.circle
              :key="`dot-${seriesKey}-${slot.label}`"
              :cx="slot.centerX"
              r="2.5"
              :initial="{ cy: baselineY, opacity: 0 }"
              :animate="{ cy: slot.y, opacity: 1, fill: slot.dotFill }"
              :transition="{
                cy: { duration: 0.42, delay: slot.index * 0.025, ease: [0.16, 1, 0.3, 1] },
                opacity: { duration: 0.25, delay: slot.index * 0.025 },
                fill: { duration: 0.18 },
              }"
            />
            <text
              :x="slot.centerX"
              :y="chartHeight - 6"
              text-anchor="middle"
              :fill="slot.isHighlighted ? '#171717' : '#737373'"
              :font-weight="slot.isHighlighted ? '700' : '500'"
              font-size="10"
            >
              {{ slot.label }}
            </text>
          </g>
        </svg>
      </div>
    </MotionConfig>
  </section>
</template>

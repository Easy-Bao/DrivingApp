<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { MotionConfig, motion } from 'motion-v'
import type { VolumeBucket } from '@/features/dashboard/composables/use-overview-metrics'
import { formatPhp } from '@/shared/utils/format'

const props = defineProps<{
  series: VolumeBucket[]
  totalTrips: number
  totalRevenuePhp: number
}>()

type ChartMetric = 'trips' | 'revenue'

const activeMetric = ref<ChartMetric>('trips')
const selectedIndex = ref<number | null>(null)

const metricOptions: { label: string; value: ChartMetric }[] = [
  { label: 'Trips', value: 'trips' },
  { label: 'Trip Fare', value: 'revenue' },
]

watch(
  () => props.series,
  () => {
    selectedIndex.value = null
  },
)

const peakIndex = computed(() => {
  if (props.series.length === 0) return 0
  return props.series.reduce((best, item, index, all) => {
    const candidate = activeMetric.value === 'trips' ? item.trips : item.revenuePhp
    const currentBest =
      activeMetric.value === 'trips' ? (all[best]?.trips ?? -1) : (all[best]?.revenuePhp ?? -1)
    return candidate > currentBest ? index : best
  }, 0)
})

const highlightedIndex = computed(() => selectedIndex.value ?? peakIndex.value)
const highlightedBucket = computed(() => props.series[highlightedIndex.value] ?? null)

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

const maxValue = computed(() => {
  const values = props.series.map((bucket) =>
    activeMetric.value === 'trips' ? bucket.trips : bucket.revenuePhp,
  )
  const rawMax = Math.max(1, ...values)
  const magnitude = Math.pow(10, Math.floor(Math.log10(rawMax)))
  return Math.ceil((rawMax * 1.15) / magnitude) * magnitude
})

const gridTicks = computed(() =>
  [0, 0.25, 0.5, 0.75, 1].map((ratio, index) => {
    const val = Math.round(maxValue.value * ratio)
    const y = padTop + plotHeight * (1 - ratio)
    const label =
      activeMetric.value === 'revenue'
        ? val >= 1000
          ? `₱${Math.round(val / 1000)}k`
          : `₱${val}`
        : val >= 1000
          ? `${(val / 1000).toFixed(1)}k`
          : String(val)
    return { index, y, label }
  }),
)

const barSlots = computed(() => {
  const count = Math.max(1, props.series.length)
  const step = plotWidth / count
  const barWidth = Math.min(44, step * 0.56)
  const isTrips = activeMetric.value === 'trips'

  return props.series.map((bucket, index) => {
    const metricVal = isTrips ? bucket.trips : bucket.revenuePhp
    const ratio = Math.max(0, metricVal / maxValue.value)
    const scaleY = Math.max(2 / plotHeight, ratio)
    const barHeight = scaleY * plotHeight
    const x = padLeft + step * index + (step - barWidth) / 2
    const y = padTop + plotHeight - barHeight
    const centerX = x + barWidth / 2
    const isHighlighted = index === highlightedIndex.value
    const barFill = isHighlighted
      ? isTrips
        ? '#171717'
        : '#059669'
      : isTrips
        ? '#d4d4d4'
        : '#a7f3d0'
    const dotFill = isHighlighted
      ? isTrips
        ? '#059669'
        : '#171717'
      : isTrips
        ? '#10b981'
        : '#059669'

    return {
      ...bucket,
      index,
      x,
      y,
      barWidth,
      barHeight,
      scaleY,
      centerX,
      barFill,
      dotFill,
      isHighlighted,
    }
  })
})

const trendPathD = computed(() =>
  barSlots.value
    .map((slot, index) => `${index === 0 ? 'M' : 'L'} ${slot.centerX} ${slot.y}`)
    .join(' '),
)

const flatBaselinePathD = computed(() =>
  barSlots.value
    .map((slot, index) => `${index === 0 ? 'M' : 'L'} ${slot.centerX} ${baselineY}`)
    .join(' '),
)

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

        <div
          class="inline-flex border border-neutral-200 bg-neutral-50 self-start sm:self-auto"
          role="group"
          aria-label="Chart metric"
        >
          <button
            v-for="option in metricOptions"
            :key="option.value"
            type="button"
            :aria-pressed="activeMetric === option.value"
            class="relative px-2.5 py-1 text-xs font-semibold transition-colors cursor-pointer"
            :class="
              activeMetric === option.value
                ? 'text-white'
                : 'text-neutral-600 hover:text-neutral-900'
            "
            @click="activeMetric = option.value"
          >
            <motion.span
              v-if="activeMetric === option.value"
              layoutId="tripVolumeMetricIndicator"
              class="absolute inset-0 rounded-none bg-neutral-900"
              :transition="{ type: 'spring', stiffness: 420, damping: 34 }"
              aria-hidden="true"
            />
            <span class="relative z-10">{{ option.label }}</span>
          </button>
        </div>
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
          {{ selectedIndex !== null ? 'Selected' : 'Peak Window' }}: {{ highlightedBucket.label }}
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
            v-if="barSlots.length > 1"
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
            v-for="slot in barSlots"
            :key="`${seriesKey}-${slot.label}`"
            class="cursor-pointer focus:outline-none"
            tabindex="0"
            @mouseenter="selectedIndex = slot.index"
            @focus="selectedIndex = slot.index"
            @click="selectedIndex = selectedIndex === slot.index ? null : slot.index"
            @mouseleave="selectedIndex = null"
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

<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import type { VolumeBucket } from '@/features/dashboard/composables/useOverviewMetrics'
import { formatPhp } from '@/shared/utils/format'

const props = defineProps<{
  series: VolumeBucket[]
  totalTrips: number
  totalRevenuePhp: number
}>()

type ChartMetric = 'trips' | 'revenue'

const activeMetric = ref<ChartMetric>('trips')
const selectedIndex = ref<number | null>(null)

watch(
  () => props.series,
  () => {
    selectedIndex.value = null
  },
)

const peakIndex = computed(() => {
  if (props.series.length === 0) return 0
  return props.series.reduce(
    (best, item, index, all) => (item.trips > (all[best]?.trips ?? -1) ? index : best),
    0,
  )
})

const highlightedIndex = computed(() => selectedIndex.value ?? peakIndex.value)
const highlightedBucket = computed(() => props.series[highlightedIndex.value] ?? null)

const averageTripFare = computed(() =>
  props.totalTrips > 0 ? props.totalRevenuePhp / props.totalTrips : 0,
)

const chartHeight = 190
const chartWidth = 600
const padLeft = 52
const padRight = 16
const padTop = 16
const padBottom = 26
const plotWidth = chartWidth - padLeft - padRight
const plotHeight = chartHeight - padTop - padBottom

const maxValue = computed(() => {
  const values = props.series.map((bucket) =>
    activeMetric.value === 'trips' ? bucket.trips : bucket.revenuePhp,
  )
  const rawMax = Math.max(1, ...values)
  const magnitude = Math.pow(10, Math.floor(Math.log10(rawMax)))
  return Math.ceil((rawMax * 1.15) / magnitude) * magnitude
})

const gridTicks = computed(() =>
  [0, 0.25, 0.5, 0.75, 1].map((ratio) => {
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
    return { y, label }
  }),
)

const barSlots = computed(() => {
  const count = Math.max(1, props.series.length)
  const step = plotWidth / count
  const barWidth = Math.min(44, step * 0.56)

  return props.series.map((bucket, index) => {
    const metricVal = activeMetric.value === 'trips' ? bucket.trips : bucket.revenuePhp
    const ratio = Math.max(0, metricVal / maxValue.value)
    const barHeight = Math.max(2, ratio * plotHeight)
    const x = padLeft + step * index + (step - barWidth) / 2
    const y = padTop + plotHeight - barHeight
    const centerX = x + barWidth / 2
    return {
      ...bucket,
      index,
      x,
      y,
      barWidth,
      barHeight,
      centerX,
    }
  })
})

const trendPolylinePoints = computed(() =>
  barSlots.value.map((slot) => `${slot.centerX},${slot.y}`).join(' '),
)
</script>

<template>
  <section class="bg-white border border-neutral-200 p-5 flex flex-col gap-4">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
      <div>
        <h2 class="font-semibold text-sm text-neutral-900">Trip Volume &amp; Revenue Trend</h2>
        <p class="text-xs text-neutral-500 mt-0.5 tabular-nums">
          Total {{ totalTrips.toLocaleString() }} trips · {{ formatPhp(totalRevenuePhp) }} · Avg
          {{ formatPhp(averageTripFare) }}
        </p>
      </div>

      <div class="inline-flex border border-neutral-200 bg-neutral-50 self-start sm:self-auto">
        <button
          type="button"
          class="px-2.5 py-1 text-xs font-semibold transition-colors cursor-pointer"
          :class="
            activeMetric === 'trips'
              ? 'bg-neutral-900 text-white'
              : 'text-neutral-600 hover:text-neutral-900'
          "
          @click="activeMetric = 'trips'"
        >
          Trips
        </button>
        <button
          type="button"
          class="px-2.5 py-1 text-xs font-semibold transition-colors cursor-pointer"
          :class="
            activeMetric === 'revenue'
              ? 'bg-neutral-900 text-white'
              : 'text-neutral-600 hover:text-neutral-900'
          "
          @click="activeMetric = 'revenue'"
        >
          Trip Fare
        </button>
      </div>
    </div>

    <div
      v-if="highlightedBucket"
      class="flex flex-wrap items-center justify-between gap-2 px-3 py-2 bg-neutral-50 border border-neutral-200 text-xs tabular-nums"
    >
      <span class="font-semibold text-neutral-900">
        {{ selectedIndex !== null ? 'Selected' : 'Peak Window' }}: {{ highlightedBucket.label }}
      </span>
      <div class="flex items-center gap-4 text-neutral-600 font-mono">
        <span>{{ highlightedBucket.trips.toLocaleString() }} trips</span>
        <span class="font-semibold text-neutral-900">
          {{ formatPhp(highlightedBucket.revenuePhp) }}
        </span>
      </div>
    </div>

    <div class="w-full overflow-x-auto">
      <svg
        :viewBox="`0 0 ${chartWidth} ${chartHeight}`"
        class="w-full min-w-[420px] h-48 select-none"
        role="img"
        aria-label="Trip volume and fare revenue chart"
      >
        <g v-for="tick in gridTicks" :key="tick.y">
          <line
            :x1="padLeft"
            :x2="chartWidth - padRight"
            :y1="tick.y"
            :y2="tick.y"
            stroke="#f0f0f0"
            stroke-width="1"
          />
          <text
            :x="padLeft - 8"
            :y="tick.y + 3"
            text-anchor="end"
            fill="#737373"
            font-size="10"
            font-family="monospace"
          >
            {{ tick.label }}
          </text>
        </g>

        <polyline
          v-if="barSlots.length > 1"
          :points="trendPolylinePoints"
          fill="none"
          stroke="#10b981"
          stroke-width="1.5"
          stroke-dasharray="3 3"
        />

        <g
          v-for="slot in barSlots"
          :key="slot.label"
          class="cursor-pointer"
          @mouseenter="selectedIndex = slot.index"
          @focus="selectedIndex = slot.index"
          @mouseleave="selectedIndex = null"
        >
          <rect
            :x="slot.x"
            :y="slot.y"
            :width="slot.barWidth"
            :height="slot.barHeight"
            :fill="slot.index === highlightedIndex ? '#171717' : '#d4d4d4'"
          />
          <circle
            :cx="slot.centerX"
            :cy="slot.y"
            r="2.5"
            :fill="slot.index === highlightedIndex ? '#059669' : '#10b981'"
          />
          <text
            :x="slot.centerX"
            :y="chartHeight - 6"
            text-anchor="middle"
            :fill="slot.index === highlightedIndex ? '#171717' : '#737373'"
            :font-weight="slot.index === highlightedIndex ? '700' : '500'"
            font-size="10"
          >
            {{ slot.label }}
          </text>
        </g>
      </svg>
    </div>
  </section>
</template>

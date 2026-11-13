<script setup lang="ts">
import { computed } from 'vue'
import type {
  BreakdownSlice,
  StatusMetric,
} from '@/features/dashboard/composables/useOverviewMetrics'

const props = defineProps<{
  totalTrips: number
  fleetMix: BreakdownSlice[]
  statusMix: StatusMetric[]
}>()

const circumference = 2 * Math.PI * 36

const ringSegments = computed(() => {
  const total = Math.max(
    1,
    props.fleetMix.reduce((sum, slice) => sum + slice.count, 0),
  )

  return props.fleetMix.reduce<Array<BreakdownSlice & { dashArray: string; dashOffset: number }>>(
    (acc, slice) => {
      const prevLength = acc.reduce((sum, prev) => sum + (prev.count / total) * circumference, 0)
      const segLength = (slice.count / total) * circumference
      acc.push({
        ...slice,
        dashArray: `${segLength} ${circumference - segLength}`,
        dashOffset: -prevLength,
      })
      return acc
    },
    [],
  )
})
</script>

<template>
  <section class="bg-white border border-neutral-200 p-5 flex flex-col justify-between gap-5">
    <div>
      <h2 class="font-semibold text-sm text-neutral-900">Fleet Mix &amp; Status</h2>
      <p class="text-xs text-neutral-500 mt-0.5">3-wheeled TukTuk and Bao-Bao distribution</p>

      <div class="mt-4 flex flex-col sm:flex-row items-center gap-4">
        <div class="relative w-24 h-24 shrink-0">
          <svg viewBox="0 0 96 96" class="w-full h-full -rotate-90" aria-hidden="true">
            <circle cx="48" cy="48" r="36" fill="none" stroke="#f5f5f5" stroke-width="10" />
            <circle
              v-for="seg in ringSegments"
              :key="seg.label"
              cx="48"
              cy="48"
              r="36"
              fill="none"
              :stroke="seg.colorHex"
              stroke-width="10"
              :stroke-dasharray="seg.dashArray"
              :stroke-dashoffset="seg.dashOffset"
            />
          </svg>
          <div class="absolute inset-0 flex flex-col items-center justify-center text-center">
            <span class="text-sm font-bold text-neutral-900 tabular-nums">
              {{ totalTrips.toLocaleString() }}
            </span>
            <span class="text-[10px] text-neutral-500 uppercase">Trips</span>
          </div>
        </div>

        <div class="w-full space-y-2.5 text-xs">
          <div
            v-for="tier in fleetMix"
            :key="tier.label"
            class="flex items-center justify-between gap-2"
          >
            <div class="flex items-center gap-2 min-w-0">
              <span class="w-2.5 h-2.5 shrink-0" :class="tier.barClass" />
              <span class="text-neutral-700 font-medium truncate">{{ tier.label }}</span>
            </div>
            <div class="font-mono text-neutral-900 font-semibold tabular-nums shrink-0">
              {{ tier.percent }}%
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="border-t border-neutral-100 pt-4 space-y-2.5">
      <div class="text-[11px] font-semibold text-neutral-500 uppercase tracking-wider">
        Dispatch Outcomes
      </div>

      <div class="flex h-2 w-full overflow-hidden bg-neutral-100" aria-hidden="true">
        <div
          v-for="item in statusMix"
          :key="item.label"
          :style="{ width: item.share }"
          :class="item.barClass"
        />
      </div>

      <div class="grid grid-cols-2 gap-x-4 gap-y-1.5 text-xs pt-1">
        <div
          v-for="item in statusMix"
          :key="item.label"
          class="flex items-center justify-between gap-2"
        >
          <span class="text-neutral-600 flex items-center gap-1.5 min-w-0">
            <span class="w-2 h-2 shrink-0" :class="item.barClass" />
            <span class="truncate">{{ item.label }}</span>
          </span>
          <span class="font-mono font-semibold text-neutral-900 tabular-nums">
            {{ item.share }}
          </span>
        </div>
      </div>
    </div>
  </section>
</template>

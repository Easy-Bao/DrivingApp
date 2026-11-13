<script setup lang="ts">
import { computed } from 'vue'
import { MotionConfig, motion } from 'motion-v'
import type {
  BreakdownSlice,
  StatusMetric,
} from '@/features/dashboard/composables/use-overview-metrics'

const props = defineProps<{
  totalTrips: number
  bookingMix: BreakdownSlice[]
  statusMix: StatusMetric[]
}>()

const circumference = 2 * Math.PI * 36
const emptyDashArray = `0.00 ${circumference.toFixed(2)}`

const ringSegments = computed(() => {
  const total = Math.max(
    1,
    props.bookingMix.reduce((sum, slice) => sum + slice.count, 0),
  )

  return props.bookingMix.reduce<Array<BreakdownSlice & { dashArray: string; dashOffset: number }>>(
    (acc, slice) => {
      const prevLength = acc.reduce((sum, prev) => sum + (prev.count / total) * circumference, 0)
      const segLength = (slice.count / total) * circumference
      const remainder = Math.max(0, circumference - segLength)
      acc.push({
        ...slice,
        dashArray: `${segLength.toFixed(2)} ${remainder.toFixed(2)}`,
        dashOffset: Number((-prevLength).toFixed(2)),
      })
      return acc
    },
    [],
  )
})
</script>

<template>
  <section class="bg-white border border-neutral-200 p-5 flex flex-col justify-between gap-5">
    <MotionConfig reducedMotion="user">
      <div>
        <h2 class="font-semibold text-sm text-neutral-900">Dispatch Breakdown</h2>
        <p class="text-xs text-neutral-500 mt-0.5">
          Breakdown by booking mode and dispatch outcome
        </p>

        <div class="mt-4 flex flex-col sm:flex-row items-center gap-4">
          <div class="relative w-24 h-24 shrink-0">
            <svg viewBox="0 0 96 96" class="w-full h-full -rotate-90" aria-hidden="true">
              <circle cx="48" cy="48" r="36" fill="none" stroke="#f5f5f5" stroke-width="10" />
              <motion.circle
                v-for="seg in ringSegments"
                :key="seg.label"
                cx="48"
                cy="48"
                r="36"
                fill="none"
                :stroke="seg.colorHex"
                stroke-width="10"
                :initial="{ strokeDasharray: emptyDashArray, strokeDashoffset: 0 }"
                :animate="{
                  strokeDasharray: seg.dashArray,
                  strokeDashoffset: seg.dashOffset,
                }"
                :transition="{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }"
              />
            </svg>
            <motion.div
              :key="totalTrips"
              :initial="{ opacity: 0, scale: 0.92 }"
              :animate="{ opacity: 1, scale: 1 }"
              :transition="{ duration: 0.22, ease: [0.16, 1, 0.3, 1] }"
              class="absolute inset-0 flex flex-col items-center justify-center text-center"
            >
              <span class="text-sm font-bold text-neutral-900 tabular-nums">
                {{ totalTrips.toLocaleString() }}
              </span>
              <span class="text-[10px] text-neutral-500 uppercase">Trips</span>
            </motion.div>
          </div>

          <div class="w-full space-y-2.5 text-xs">
            <div
              v-for="mode in bookingMix"
              :key="mode.label"
              class="flex items-center justify-between gap-2"
            >
              <div class="flex items-center gap-2 min-w-0">
                <span class="w-2.5 h-2.5 shrink-0" :class="mode.barClass" />
                <div class="min-w-0">
                  <div class="text-neutral-700 font-medium truncate">{{ mode.label }}</div>
                  <div class="text-[11px] text-neutral-400 tabular-nums">
                    {{ mode.count.toLocaleString() }} trips
                  </div>
                </div>
              </div>
              <motion.span
                :key="`${mode.label}-${mode.percent}`"
                :initial="{ opacity: 0.35, y: 2 }"
                :animate="{ opacity: 1, y: 0 }"
                :transition="{ duration: 0.2 }"
                class="font-mono text-neutral-900 font-semibold tabular-nums shrink-0"
              >
                {{ mode.percent }}%
              </motion.span>
            </div>
          </div>
        </div>
      </div>

      <div class="border-t border-neutral-100 pt-4 space-y-2.5">
        <div class="text-[11px] font-semibold text-neutral-500 uppercase tracking-wider">
          Dispatch Outcomes
        </div>

        <div class="flex h-2 w-full overflow-hidden bg-neutral-100" aria-hidden="true">
          <motion.div
            v-for="item in statusMix"
            :key="item.label"
            :initial="{ width: '0%' }"
            :animate="{ width: item.share }"
            :transition="{ duration: 0.45, ease: [0.16, 1, 0.3, 1] }"
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
            <motion.span
              :key="`${item.label}-${item.share}`"
              :initial="{ opacity: 0.35, y: 2 }"
              :animate="{ opacity: 1, y: 0 }"
              :transition="{ duration: 0.2 }"
              class="font-mono font-semibold text-neutral-900 tabular-nums"
            >
              {{ item.share }}
            </motion.span>
          </div>
        </div>
      </div>
    </MotionConfig>
  </section>
</template>

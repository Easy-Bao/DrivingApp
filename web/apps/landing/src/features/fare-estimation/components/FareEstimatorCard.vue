<script setup lang="ts">
import { AnimatePresence, motion } from 'motion-v'
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import {
  farePrefillSignal,
  useFareEstimation,
} from '@/features/fare-estimation/composables/useFareEstimation'
import type { RideTier } from '@/features/fare-estimation/types'

const TIER_ORDER: RideTier[] = ['standard', 'comfort', 'executive']
const EASE = [0.22, 1, 0.36, 1] as const

const {
  request,
  estimate,
  isCalculating,
  validationError,
  activePresetId,
  presets,
  tierConfigs,
  estimateFare,
  selectPreset,
  selectTier,
  applyExternalPrefill,
  swapLocations,
} = useFareEstimation()

const highlighted = ref(false)
const swapCount = ref(0)
let highlightTimer: ReturnType<typeof setTimeout> | null = null

const handleSwap = async () => {
  swapCount.value += 1
  await swapLocations()
}

watch(farePrefillSignal, async (payload) => {
  if (!payload) {
    return
  }
  await applyExternalPrefill(payload)
  highlighted.value = true
  if (highlightTimer) {
    clearTimeout(highlightTimer)
  }
  highlightTimer = setTimeout(() => {
    highlighted.value = false
  }, 700)
})

onBeforeUnmount(() => {
  if (highlightTimer) {
    clearTimeout(highlightTimer)
  }
})

const floorFarePhp = computed(() => {
  if (!estimate.value) {
    return 0
  }
  return Math.round(estimate.value.estimatedFareCents / 100)
})

const formatPresetLabel = (label: string) => label.replace('->', '→')
</script>

<template>
  <section
    aria-labelledby="fare-card-heading"
    class="rounded-2xl border bg-white p-6 shadow-[0_20px_48px_-24px_rgba(9,13,22,0.12),0_1px_3px_rgba(9,13,22,0.04)] transition-all duration-300 sm:p-7"
    :class="
      highlighted
        ? 'border-neutral-950 ring-4 ring-neutral-950/8'
        : 'border-neutral-200/85 ring-1 ring-transparent'
    "
  >
    <div class="flex items-center justify-between gap-3">
      <h2 id="fare-card-heading" class="text-lg font-bold tracking-[-0.02em] text-neutral-950">
        Fare Estimate
      </h2>
      <span
        class="rounded-full border border-neutral-200/80 bg-neutral-50 px-2.5 py-0.5 text-[11px] font-semibold tracking-wide text-neutral-500"
      >
        PHP
      </span>
    </div>

    <div class="mt-4 flex flex-wrap gap-1.5">
      <button
        v-for="corridor in presets.slice(0, 3)"
        :key="corridor.id"
        type="button"
        class="rounded-full border px-3 py-1.5 text-xs font-medium transition-all duration-150"
        :class="
          activePresetId === corridor.id
            ? 'border-neutral-950 bg-neutral-950 text-white shadow-[0_2px_8px_-2px_rgba(9,13,22,0.28)]'
            : 'border-neutral-200/85 bg-neutral-50/80 text-neutral-600 hover:border-neutral-300 hover:bg-neutral-100/70 hover:text-neutral-950'
        "
        @click="selectPreset(corridor)"
      >
        {{ formatPresetLabel(corridor.label) }}
      </button>
    </div>

    <form class="mt-5 space-y-4" @submit.prevent="estimateFare">
      <div
        class="relative rounded-xl border border-neutral-200/80 bg-neutral-50/75 p-3.5 pr-13 pl-8 sm:p-4 sm:pr-14 sm:pl-9"
      >
        <!-- Minimalist pickup-to-dropoff route rail -->
        <div
          class="pointer-events-none absolute top-[2.35rem] bottom-[1.7rem] left-3.5 flex flex-col items-center sm:left-4"
          aria-hidden="true"
        >
          <span class="h-2 w-2 rounded-full border-[1.75px] border-neutral-950 bg-white" />
          <span class="my-1 w-px flex-1 border-l border-dashed border-neutral-300" />
          <span class="h-2 w-2 rounded-full bg-emerald-600" />
        </div>

        <div class="space-y-3">
          <div>
            <label
              for="landing-pickup-input"
              class="block text-[11px] font-semibold text-neutral-500"
            >
              Pickup
            </label>
            <input
              id="landing-pickup-input"
              v-model="request.pickupLocation"
              type="text"
              autocomplete="off"
              placeholder="Agora Public Market"
              class="mt-1 w-full rounded-lg border border-neutral-200/90 bg-white px-3 py-2 text-sm text-neutral-950 shadow-[0_1px_2px_rgba(0,0,0,0.02)] placeholder:text-neutral-400 transition-[border-color,box-shadow] duration-150 focus:border-neutral-950 focus:shadow-[0_0_0_1px_#090d16] focus:outline-none"
              @input="activePresetId = null"
            />
          </div>

          <div>
            <label
              for="landing-destination-input"
              class="block text-[11px] font-semibold text-neutral-500"
            >
              Drop-off
            </label>
            <input
              id="landing-destination-input"
              v-model="request.destinationLocation"
              type="text"
              autocomplete="off"
              placeholder="Dao Provincial Capitol"
              class="mt-1 w-full rounded-lg border border-neutral-200/90 bg-white px-3 py-2 text-sm text-neutral-950 shadow-[0_1px_2px_rgba(0,0,0,0.02)] placeholder:text-neutral-400 transition-[border-color,box-shadow] duration-150 focus:border-neutral-950 focus:shadow-[0_0_0_1px_#090d16] focus:outline-none"
              @input="activePresetId = null"
            />
          </div>
        </div>

        <motion.button
          type="button"
          aria-label="Swap pickup and destination"
          title="Swap"
          :while-press="{ scale: 0.9 }"
          class="absolute top-1/2 right-2.5 flex h-8 w-8 -translate-y-1/2 items-center justify-center rounded-full border border-neutral-200/90 bg-white text-neutral-500 shadow-[0_1px_3px_rgba(9,13,22,0.06)] transition-colors hover:border-neutral-400 hover:text-neutral-950 sm:right-3"
          @click="handleSwap"
        >
          <motion.svg
            width="14"
            height="14"
            viewBox="0 0 24 24"
            fill="none"
            aria-hidden="true"
            :animate="{ rotate: swapCount * 180 }"
            :transition="{ type: 'spring', stiffness: 360, damping: 24 }"
          >
            <path
              d="M7 16V4m0 0L3.5 7.5M7 4l3.5 3.5M17 8v12m0 0l3.5-3.5M17 20l-3.5-3.5"
              stroke="currentColor"
              stroke-width="1.9"
              stroke-linecap="round"
              stroke-linejoin="round"
            />
          </motion.svg>
        </motion.button>
      </div>

      <div>
        <span id="ride-tier-label" class="sr-only">Ride Tier</span>
        <div role="radiogroup" aria-labelledby="ride-tier-label" class="grid grid-cols-3 gap-2">
          <button
            v-for="tierKey in TIER_ORDER"
            :key="tierKey"
            type="button"
            role="radio"
            :aria-checked="request.rideTier === tierKey"
            class="rounded-xl border px-3 py-2.5 text-left transition-all duration-150"
            :class="
              request.rideTier === tierKey
                ? 'border-neutral-950 bg-neutral-50 text-neutral-950 ring-1 ring-neutral-950/10'
                : 'border-neutral-200/85 bg-white text-neutral-600 hover:border-neutral-300 hover:bg-neutral-50/50 hover:text-neutral-950'
            "
            @click="selectTier(tierKey)"
          >
            <span class="flex items-center justify-between gap-1">
              <span class="text-xs font-bold">{{ tierConfigs[tierKey].shortLabel }}</span>
              <span
                class="h-1.5 w-1.5 rounded-full transition-colors"
                :class="request.rideTier === tierKey ? 'bg-neutral-950' : 'bg-transparent'"
                aria-hidden="true"
              />
            </span>
            <span class="mt-0.5 block text-[11px] font-medium tabular-nums text-neutral-500">
              &#8369;{{ tierConfigs[tierKey].basePhp }}
            </span>
          </button>
        </div>
      </div>

      <AnimatePresence>
        <motion.p
          v-if="validationError"
          key="fare-validation-error"
          role="alert"
          :initial="{ opacity: 0, y: -4 }"
          :animate="{ opacity: 1, y: 0 }"
          :exit="{ opacity: 0, y: -4 }"
          :transition="{ duration: 0.18, ease: EASE }"
          class="rounded-xl border border-rose-200/90 bg-rose-50/70 px-3.5 py-2.5 text-xs font-medium text-rose-800"
        >
          {{ validationError }}
        </motion.p>
      </AnimatePresence>

      <div
        v-if="estimate"
        aria-live="polite"
        class="rounded-xl border border-neutral-200/75 bg-neutral-50/80 px-4 py-4"
      >
        <div class="flex flex-wrap items-baseline justify-between gap-3">
          <div>
            <span class="block text-[11px] font-semibold tracking-wide text-neutral-500 uppercase">
              Floor Fare
            </span>
            <motion.span
              :key="floorFarePhp"
              :initial="{ opacity: 0, y: 4 }"
              :animate="{ opacity: 1, y: 0 }"
              :transition="{ duration: 0.22, ease: EASE }"
              class="mt-0.5 block text-3xl font-bold tracking-tight tabular-nums text-neutral-950"
            >
              &#8369;{{ floorFarePhp }}
            </motion.span>
          </div>

          <div class="text-right">
            <span
              class="inline-flex items-center rounded-full border border-neutral-200/80 bg-white px-2.5 py-1 text-xs font-medium tabular-nums text-neutral-600"
            >
              {{ estimate.estimatedDistanceKm.toFixed(1) }} km ·
              {{ estimate.estimatedDurationMinutes }} min
            </span>
            <p class="mt-1.5 text-[11px] tabular-nums text-neutral-500">
              Typical bids &#8369;{{ estimate.suggestedBidRangePhp.min }}–&#8369;{{
                estimate.suggestedBidRangePhp.max
              }}
            </p>
          </div>
        </div>

        <p
          v-if="estimate.corridorNote"
          class="mt-3 border-t border-neutral-200/70 pt-2.5 text-[11px] text-neutral-500"
        >
          {{ estimate.corridorNote }}
        </p>
      </div>

      <div class="grid gap-2.5 pt-1 sm:grid-cols-2">
        <button
          type="submit"
          :disabled="isCalculating"
          class="inline-flex min-h-11 w-full items-center justify-center rounded-xl border border-neutral-200/90 bg-white px-4 py-2.5 text-sm font-semibold text-neutral-900 shadow-[0_1px_2px_rgba(0,0,0,0.03)] transition-all duration-150 hover:border-neutral-300 hover:bg-neutral-50 active:scale-[0.985] disabled:opacity-60"
        >
          {{ isCalculating ? 'Calculating...' : 'Estimate' }}
        </button>

        <RouterLink
          :to="{
            path: '/download',
            query: {
              from: request.pickupLocation,
              to: request.destinationLocation,
              tier: request.rideTier,
              fare: String(floorFarePhp),
            },
          }"
          class="inline-flex min-h-11 w-full items-center justify-center rounded-xl bg-neutral-950 px-4 py-2.5 text-sm font-semibold text-white shadow-[0_6px_16px_-6px_rgba(9,13,22,0.35)] transition-all duration-150 hover:bg-neutral-800 active:scale-[0.985]"
        >
          Open App
        </RouterLink>
      </div>
    </form>
  </section>
</template>

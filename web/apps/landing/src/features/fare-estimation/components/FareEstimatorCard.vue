<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import {
  farePrefillSignal,
  useFareEstimation,
} from '@/features/fare-estimation/composables/useFareEstimation'
import type { RideTier } from '@/features/fare-estimation/types'

const TIER_ORDER: RideTier[] = ['standard', 'comfort', 'executive']

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
let highlightTimer: ReturnType<typeof setTimeout> | null = null

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
</script>

<template>
  <section
    aria-labelledby="fare-card-heading"
    class="border bg-white p-5 transition-colors sm:p-6"
    :class="highlighted ? 'border-neutral-900' : 'border-neutral-200'"
  >
    <div class="flex items-center justify-between gap-2">
      <h2 id="fare-card-heading" class="text-lg font-bold tracking-tight text-neutral-900">
        Fare Estimate
      </h2>
      <span class="text-xs font-medium text-neutral-500">PHP</span>
    </div>

    <div class="mt-3 flex flex-wrap gap-1.5">
      <button
        v-for="corridor in presets.slice(0, 3)"
        :key="corridor.id"
        type="button"
        class="border px-2.5 py-1 text-xs font-medium transition-colors"
        :class="
          activePresetId === corridor.id
            ? 'border-neutral-900 bg-neutral-900 text-white'
            : 'border-neutral-200 bg-neutral-50 text-neutral-600 hover:text-neutral-900'
        "
        @click="selectPreset(corridor)"
      >
        {{ corridor.label }}
      </button>
    </div>

    <form class="mt-4 space-y-3" @submit.prevent="estimateFare">
      <div class="relative space-y-2.5 border border-neutral-200 bg-neutral-50 p-3 pr-12">
        <div>
          <label for="landing-pickup-input" class="block text-xs font-medium text-neutral-600">
            Pickup
          </label>
          <input
            id="landing-pickup-input"
            v-model="request.pickupLocation"
            type="text"
            autocomplete="off"
            placeholder="Agora Public Market"
            class="mt-1 w-full border border-neutral-300 bg-white px-3 py-2 text-sm text-neutral-900 placeholder:text-neutral-400 focus:border-neutral-900 focus:outline-none"
            @input="activePresetId = null"
          />
        </div>

        <div>
          <label for="landing-destination-input" class="block text-xs font-medium text-neutral-600">
            Drop-off
          </label>
          <input
            id="landing-destination-input"
            v-model="request.destinationLocation"
            type="text"
            autocomplete="off"
            placeholder="Dao Provincial Capitol"
            class="mt-1 w-full border border-neutral-300 bg-white px-3 py-2 text-sm text-neutral-900 placeholder:text-neutral-400 focus:border-neutral-900 focus:outline-none"
            @input="activePresetId = null"
          />
        </div>

        <button
          type="button"
          aria-label="Swap pickup and destination"
          title="Swap"
          class="absolute right-2.5 top-1/2 flex h-8 w-8 -translate-y-1/2 items-center justify-center border border-neutral-300 bg-white text-neutral-600 hover:border-neutral-900 hover:text-neutral-900"
          @click="swapLocations"
        >
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" aria-hidden="true">
            <path
              d="M7 16V4m0 0L3.5 7.5M7 4l3.5 3.5M17 8v12m0 0l3.5-3.5M17 20l-3.5-3.5"
              stroke="currentColor"
              stroke-width="1.9"
              stroke-linecap="round"
              stroke-linejoin="round"
            />
          </svg>
        </button>
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
            class="border px-3 py-2 text-left transition-colors"
            :class="
              request.rideTier === tierKey
                ? 'border-neutral-900 bg-neutral-100 text-neutral-900'
                : 'border-neutral-200 bg-white text-neutral-600 hover:border-neutral-300 hover:text-neutral-900'
            "
            @click="selectTier(tierKey)"
          >
            <span class="block text-xs font-bold">{{ tierConfigs[tierKey].shortLabel }}</span>
            <span class="block text-[11px] tabular-nums"
              >&#8369;{{ tierConfigs[tierKey].basePhp }}</span
            >
          </button>
        </div>
      </div>

      <p
        v-if="validationError"
        role="alert"
        class="border border-neutral-300 border-l-2 border-l-rose-600 bg-neutral-50 px-3 py-2 text-xs font-medium text-neutral-900"
      >
        {{ validationError }}
      </p>

      <div
        v-if="estimate"
        aria-live="polite"
        class="flex items-baseline justify-between border-t border-neutral-200 pt-4"
      >
        <div>
          <span class="block text-xs font-medium text-neutral-500">Floor Fare</span>
          <span class="text-3xl font-bold tracking-tight tabular-nums text-neutral-900">
            &#8369;{{ floorFarePhp }}
          </span>
        </div>
        <span class="text-xs font-medium tabular-nums text-neutral-500">
          {{ estimate.estimatedDistanceKm.toFixed(1) }} km ·
          {{ estimate.estimatedDurationMinutes }} min
        </span>
      </div>

      <div class="grid gap-2 pt-1 sm:grid-cols-2">
        <button
          type="submit"
          :disabled="isCalculating"
          class="inline-flex min-h-10 w-full items-center justify-center border border-neutral-300 bg-white px-4 py-2 text-sm font-semibold text-neutral-900 transition-colors hover:bg-neutral-100 disabled:opacity-60"
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
          class="inline-flex min-h-10 w-full items-center justify-center bg-neutral-900 px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-neutral-800"
        >
          Open App
        </RouterLink>
      </div>
    </form>
  </section>
</template>

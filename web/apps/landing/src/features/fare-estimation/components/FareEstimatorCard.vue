<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import {
  farePrefillSignal,
  useFareEstimation,
} from '@/features/fare-estimation/composables/useFareEstimation'
import type { RideTier } from '@/features/fare-estimation/types'
import UiIcon from '@/shared/components/UiIcon.vue'

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

const highlightPulse = ref(false)
let highlightTimer: ReturnType<typeof setTimeout> | null = null

watch(farePrefillSignal, async (payload) => {
  if (!payload) {
    return
  }
  await applyExternalPrefill(payload)
  highlightPulse.value = true
  if (highlightTimer) {
    clearTimeout(highlightTimer)
  }
  highlightTimer = setTimeout(() => {
    highlightPulse.value = false
  }, 900)
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

const selectedTierConfig = computed(() => tierConfigs[request.rideTier])

const fareFormulaSummary = computed(() => {
  if (!estimate.value) {
    return ''
  }
  const extraKm = Math.max(0, Number((estimate.value.estimatedDistanceKm - 1).toFixed(1)))
  return `₱${selectedTierConfig.value.basePhp} flag-down + ${extraKm} km × ₱${selectedTierConfig.value.perKmPhp}/km`
})
</script>

<template>
  <section
    aria-labelledby="fare-card-heading"
    class="rounded-3xl border bg-white p-5 shadow-2xl shadow-slate-900/10 transition-all duration-300 sm:p-6"
    :class="
      highlightPulse ? 'border-emerald-500 ring-4 ring-emerald-500/20' : 'border-slate-200/90'
    "
  >
    <div class="flex flex-wrap items-center justify-between gap-2">
      <div>
        <p class="text-[11px] font-bold uppercase tracking-wider text-emerald-700">
          Pagadian City Tariff Preview
        </p>
        <h2
          id="fare-card-heading"
          class="mt-0.5 text-lg font-extrabold tracking-tight text-[#090d16]"
        >
          Check your upfront fare floor
        </h2>
      </div>
      <span
        class="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-800 ring-1 ring-emerald-200"
      >
        <span
          class="h-1.5 w-1.5 rounded-full bg-emerald-600 motion-safe:animate-pulse"
          aria-hidden="true"
        />
        90s live bidding
      </span>
    </div>

    <div class="mt-4">
      <p class="text-xs font-medium text-slate-600">Popular Pagadian corridors:</p>
      <div class="mt-2 flex flex-wrap gap-1.5">
        <button
          v-for="corridor in presets"
          :key="corridor.id"
          type="button"
          class="rounded-full px-3 py-1.5 text-xs font-semibold transition-colors"
          :class="
            activePresetId === corridor.id
              ? 'bg-[#090d16] text-white'
              : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
          "
          @click="selectPreset(corridor)"
        >
          {{ corridor.label }}
        </button>
      </div>
    </div>

    <form class="mt-4 space-y-3" @submit.prevent="estimateFare">
      <div class="relative rounded-2xl border border-slate-200 bg-slate-50/75 p-3">
        <div class="space-y-2.5 pr-11">
          <div>
            <label
              for="landing-pickup-input"
              class="flex items-center gap-2 text-xs font-semibold text-slate-700"
            >
              <span
                class="h-2.5 w-2.5 rounded-full bg-emerald-600 ring-4 ring-emerald-100"
                aria-hidden="true"
              />
              Pickup point
            </label>
            <input
              id="landing-pickup-input"
              v-model="request.pickupLocation"
              type="text"
              autocomplete="off"
              placeholder="e.g., Agora Public Market, Poblacion"
              class="mt-1 w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-[#090d16] placeholder:text-slate-400"
              @input="activePresetId = null"
            />
          </div>

          <div>
            <label
              for="landing-destination-input"
              class="flex items-center gap-2 text-xs font-semibold text-slate-700"
            >
              <span
                class="h-2.5 w-2.5 rounded-full bg-amber-500 ring-4 ring-amber-100"
                aria-hidden="true"
              />
              Drop-off landmark
            </label>
            <input
              id="landing-destination-input"
              v-model="request.destinationLocation"
              type="text"
              autocomplete="off"
              placeholder="e.g., Dao Capitol or Bulatok Terminal"
              class="mt-1 w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-[#090d16] placeholder:text-slate-400"
              @input="activePresetId = null"
            />
          </div>
        </div>

        <button
          type="button"
          aria-label="Swap pickup and destination"
          title="Swap pickup and destination"
          class="absolute right-3 top-1/2 flex h-9 w-9 -translate-y-1/2 items-center justify-center rounded-xl border border-slate-200 bg-white text-slate-700 shadow-xs transition-colors hover:border-emerald-300 hover:bg-emerald-50 hover:text-emerald-800"
          @click="swapLocations"
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden="true">
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
        <span id="ride-tier-label" class="block text-xs font-semibold text-slate-700">
          Choose Taxicle unit tier
        </span>
        <div
          role="radiogroup"
          aria-labelledby="ride-tier-label"
          class="mt-1.5 grid grid-cols-3 gap-2"
        >
          <button
            v-for="tierKey in TIER_ORDER"
            :key="tierKey"
            type="button"
            role="radio"
            :aria-checked="request.rideTier === tierKey"
            class="flex flex-col items-start rounded-2xl border p-2.5 text-left transition-all"
            :class="
              request.rideTier === tierKey
                ? 'border-emerald-600 bg-emerald-50/90 text-[#090d16] shadow-xs ring-1 ring-emerald-600/20'
                : 'border-slate-200 bg-white text-slate-700 hover:border-slate-300 hover:bg-slate-50'
            "
            @click="selectTier(tierKey)"
          >
            <span class="text-xs font-bold leading-tight">
              {{ tierConfigs[tierKey].shortLabel }}
            </span>
            <span class="mt-0.5 text-[11px] font-semibold tabular-nums text-emerald-800">
              &#8369;{{ tierConfigs[tierKey].basePhp }} base
            </span>
          </button>
        </div>
        <p class="mt-1.5 text-xs text-slate-600">
          {{ selectedTierConfig.vehicleExample }} · {{ selectedTierConfig.capacityText }}
        </p>
      </div>

      <p
        v-if="validationError"
        role="alert"
        class="rounded-xl border border-rose-200 bg-rose-50 px-3 py-2 text-xs font-medium text-rose-800"
      >
        {{ validationError }}
      </p>

      <div
        v-if="estimate"
        aria-live="polite"
        class="rounded-2xl border border-emerald-200 bg-linear-to-br from-emerald-50 via-white to-slate-50 p-4"
      >
        <div class="flex flex-wrap items-end justify-between gap-3">
          <div>
            <p class="text-[11px] font-bold uppercase tracking-wider text-emerald-800">
              Guaranteed Fare Floor
            </p>
            <p class="mt-0.5 text-3xl font-extrabold tracking-tight tabular-nums text-[#090d16]">
              &#8369;{{ floorFarePhp }}
            </p>
          </div>
          <div class="text-right">
            <p class="text-xs font-semibold tabular-nums text-slate-700">
              Likely driver bids: &#8369;{{ estimate.suggestedBidRangePhp.min }}&ndash;&#8369;{{
                estimate.suggestedBidRangePhp.max
              }}
            </p>
            <p class="mt-0.5 text-xs tabular-nums text-slate-600">
              ~{{ estimate.estimatedDistanceKm.toFixed(1) }} km ·
              {{ estimate.estimatedDurationMinutes }}
              min ETA
            </p>
          </div>
        </div>

        <p
          class="mt-2 rounded-lg bg-white/80 px-2.5 py-1 text-[11px] font-medium tabular-nums text-slate-600 ring-1 ring-emerald-200/70"
        >
          {{ fareFormulaSummary }}
        </p>

        <div
          class="mt-3 flex flex-wrap items-center justify-between gap-2 border-t border-emerald-200/70 pt-2.5 text-xs text-slate-600"
        >
          <span>{{ estimate.corridorNote }}</span>
          <span class="font-semibold text-emerald-800">{{ estimate.surgeCapLabel }}</span>
        </div>
      </div>

      <div class="grid gap-2.5 sm:grid-cols-2">
        <button
          type="submit"
          :disabled="isCalculating"
          class="inline-flex min-h-11 w-full items-center justify-center gap-2 rounded-xl border border-slate-300 bg-white px-4 py-2.5 text-sm font-bold text-[#090d16] transition-colors hover:bg-slate-50 disabled:opacity-60"
        >
          <span>{{ isCalculating ? 'Calculating...' : 'Estimate Fare' }}</span>
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
          class="inline-flex min-h-11 w-full items-center justify-center gap-2 rounded-xl bg-emerald-700 px-4 py-2.5 text-sm font-bold text-white shadow-xs transition-colors hover:bg-emerald-800"
        >
          <span>Book in EasyRide App</span>
          <UiIcon name="arrow-right" size-class="h-4 w-4" />
        </RouterLink>
      </div>
    </form>
  </section>
</template>

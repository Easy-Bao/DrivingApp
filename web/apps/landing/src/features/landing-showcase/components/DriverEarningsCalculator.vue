<script setup lang="ts">
import { computed, ref } from 'vue'
import { COMMISSION_TIERS } from '@/features/landing-showcase/data/landingContent'

const selectedTierId = ref<string>(COMMISSION_TIERS[0]?.id ?? 'standard')
const dailyTrips = ref(18)
const avgFarePhp = ref(60)
const workingDaysPerWeek = ref(6)

const activeTier = computed(() => {
  return COMMISSION_TIERS.find((tier) => tier.id === selectedTierId.value) ?? COMMISSION_TIERS[0]
})

const grossDailyPhp = computed(() => dailyTrips.value * avgFarePhp.value)

const commissionDeductionPhp = computed(() => {
  const rate = activeTier.value?.ratePercent ?? 15
  return Math.round((grossDailyPhp.value * rate) / 100)
})

const netDailyPhp = computed(() => grossDailyPhp.value - commissionDeductionPhp.value)
const netWeeklyPhp = computed(() => netDailyPhp.value * workingDaysPerWeek.value)
</script>

<template>
  <section
    aria-labelledby="driver-earnings-heading"
    class="border border-neutral-200 bg-white p-6 sm:p-8"
  >
    <h2 id="driver-earnings-heading" class="text-xl font-bold tracking-tight text-neutral-900">
      Earnings Estimate
    </h2>

    <div class="mt-6 grid gap-8 lg:grid-cols-12">
      <div class="space-y-5 lg:col-span-6">
        <div class="grid grid-cols-3 gap-2">
          <button
            v-for="tier in COMMISSION_TIERS"
            :key="tier.id"
            type="button"
            class="border p-3 text-left transition-colors"
            :class="
              selectedTierId === tier.id
                ? 'border-neutral-900 bg-neutral-100 text-neutral-900'
                : 'border-neutral-200 bg-white text-neutral-500 hover:border-neutral-300 hover:text-neutral-900'
            "
            @click="selectedTierId = tier.id"
          >
            <span class="block text-xs font-bold">{{ tier.tierName }}</span>
            <span class="mt-0.5 block text-sm font-bold tabular-nums">{{ tier.ratePercent }}%</span>
          </button>
        </div>

        <div>
          <div class="flex items-center justify-between text-xs font-medium text-neutral-600">
            <label for="calc-daily-trips">Daily trips</label>
            <span class="font-bold tabular-nums text-neutral-900">{{ dailyTrips }}</span>
          </div>
          <input
            id="calc-daily-trips"
            v-model.number="dailyTrips"
            type="range"
            min="6"
            max="36"
            step="1"
            class="mt-2 w-full accent-neutral-900"
          />
        </div>

        <div>
          <div class="flex items-center justify-between text-xs font-medium text-neutral-600">
            <label for="calc-avg-fare">Average fare</label>
            <span class="font-bold tabular-nums text-neutral-900">&#8369;{{ avgFarePhp }}</span>
          </div>
          <input
            id="calc-avg-fare"
            v-model.number="avgFarePhp"
            type="range"
            min="30"
            max="120"
            step="5"
            class="mt-2 w-full accent-neutral-900"
          />
        </div>

        <div class="flex gap-2">
          <button
            v-for="days in [5, 6, 7]"
            :key="days"
            type="button"
            class="border px-3.5 py-1.5 text-xs font-semibold tabular-nums transition-colors"
            :class="
              workingDaysPerWeek === days
                ? 'border-neutral-900 bg-neutral-900 text-white'
                : 'border-neutral-300 bg-white text-neutral-600 hover:text-neutral-900'
            "
            @click="workingDaysPerWeek = days"
          >
            {{ days }} days
          </button>
        </div>
      </div>

      <div
        class="flex flex-col justify-between border border-neutral-200 bg-neutral-50 p-6 lg:col-span-6"
      >
        <div
          class="flex flex-wrap items-baseline justify-between gap-4 border-b border-neutral-200 pb-5"
        >
          <div>
            <p class="text-xs font-medium text-neutral-500">Daily Net</p>
            <p class="mt-1 text-3xl font-bold tracking-tight tabular-nums text-neutral-900">
              &#8369;{{ netDailyPhp.toLocaleString() }}
            </p>
          </div>
          <div class="text-right">
            <p class="text-xs font-medium text-neutral-500">{{ workingDaysPerWeek }}-Day Net</p>
            <p class="mt-1 text-2xl font-bold tabular-nums text-neutral-900">
              &#8369;{{ netWeeklyPhp.toLocaleString() }}
            </p>
          </div>
        </div>

        <dl class="mt-5 space-y-2.5 text-sm">
          <div class="flex items-center justify-between">
            <dt class="text-neutral-500">Gross cash</dt>
            <dd class="font-semibold tabular-nums text-neutral-900">
              &#8369;{{ grossDailyPhp.toLocaleString() }}
            </dd>
          </div>
          <div class="flex items-center justify-between">
            <dt class="text-neutral-500">Fee ({{ activeTier?.ratePercent }}%)</dt>
            <dd class="font-semibold tabular-nums text-neutral-600">
              -&#8369;{{ commissionDeductionPhp.toLocaleString() }}
            </dd>
          </div>
        </dl>
      </div>
    </div>
  </section>
</template>

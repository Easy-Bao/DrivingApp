<script setup lang="ts">
import { motion } from 'motion-v'
import { computed, ref } from 'vue'
import { COMMISSION_TIERS } from '@/features/landing-showcase/data/landingContent'

const EASE = [0.22, 1, 0.36, 1] as const

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
    class="rounded-2xl border border-neutral-200/85 bg-white p-6 shadow-[0_20px_48px_-24px_rgba(9,13,22,0.1),0_1px_3px_rgba(9,13,22,0.04)] sm:p-8"
  >
    <div class="flex flex-wrap items-baseline justify-between gap-2">
      <h2
        id="driver-earnings-heading"
        class="text-xl font-bold tracking-[-0.02em] text-neutral-950"
      >
        Earnings Estimate
      </h2>
      <span class="text-xs text-neutral-500">
        {{ activeTier?.note }} · {{ activeTier?.ratePercent }}% platform fee
      </span>
    </div>

    <div class="mt-6 grid gap-8 lg:grid-cols-12">
      <div class="space-y-6 lg:col-span-6">
        <div class="grid grid-cols-3 gap-2.5">
          <button
            v-for="tier in COMMISSION_TIERS"
            :key="tier.id"
            type="button"
            class="rounded-xl border p-3.5 text-left transition-all duration-150"
            :class="
              selectedTierId === tier.id
                ? 'border-neutral-950 bg-neutral-50 text-neutral-950 ring-1 ring-neutral-950/10'
                : 'border-neutral-200/85 bg-white text-neutral-500 hover:border-neutral-300 hover:bg-neutral-50/50 hover:text-neutral-950'
            "
            @click="selectedTierId = tier.id"
          >
            <span class="flex items-center justify-between gap-1">
              <span class="text-xs font-bold">{{ tier.tierName }}</span>
              <span
                class="h-1.5 w-1.5 rounded-full transition-colors"
                :class="selectedTierId === tier.id ? 'bg-neutral-950' : 'bg-transparent'"
                aria-hidden="true"
              />
            </span>
            <span class="mt-1 block text-base font-bold tabular-nums text-neutral-950">
              {{ tier.ratePercent }}%
            </span>
          </button>
        </div>

        <div class="space-y-5">
          <div>
            <div class="flex items-center justify-between text-xs font-medium text-neutral-600">
              <label for="calc-daily-trips">Daily trips</label>
              <span
                class="rounded-full bg-neutral-100 px-2.5 py-0.5 font-bold tabular-nums text-neutral-950"
              >
                {{ dailyTrips }} trips
              </span>
            </div>
            <input
              id="calc-daily-trips"
              v-model.number="dailyTrips"
              type="range"
              min="6"
              max="36"
              step="1"
              class="range-slider mt-3 w-full"
            />
          </div>

          <div>
            <div class="flex items-center justify-between text-xs font-medium text-neutral-600">
              <label for="calc-avg-fare">Average fare</label>
              <span
                class="rounded-full bg-neutral-100 px-2.5 py-0.5 font-bold tabular-nums text-neutral-950"
              >
                &#8369;{{ avgFarePhp }}
              </span>
            </div>
            <input
              id="calc-avg-fare"
              v-model.number="avgFarePhp"
              type="range"
              min="30"
              max="120"
              step="5"
              class="range-slider mt-3 w-full"
            />
          </div>
        </div>

        <div>
          <p class="text-xs font-medium text-neutral-500">Driving days per week</p>
          <div
            class="mt-2.5 inline-flex rounded-full border border-neutral-200/90 bg-neutral-50 p-1"
          >
            <button
              v-for="days in [5, 6, 7]"
              :key="days"
              type="button"
              class="relative z-10 rounded-full px-4 py-1.5 text-xs font-semibold tabular-nums transition-colors duration-150"
              :class="
                workingDaysPerWeek === days
                  ? 'text-white'
                  : 'text-neutral-600 hover:text-neutral-950'
              "
              @click="workingDaysPerWeek = days"
            >
              <motion.span
                v-if="workingDaysPerWeek === days"
                layout-id="driver-days-pill"
                :transition="{ type: 'spring', stiffness: 460, damping: 34 }"
                class="absolute inset-0 -z-10 rounded-full bg-neutral-950 shadow-xs"
                aria-hidden="true"
              />
              {{ days }} days
            </button>
          </div>
        </div>
      </div>

      <div
        class="relative flex flex-col justify-between overflow-hidden rounded-2xl bg-[#090d16] p-6 text-white ring-1 ring-inset ring-white/10 sm:p-7 lg:col-span-6"
      >
        <div
          class="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_70%_70%_at_90%_0%,rgba(5,150,105,0.18),transparent_60%)]"
          aria-hidden="true"
        />

        <div
          class="relative flex flex-wrap items-baseline justify-between gap-4 border-b border-white/10 pb-6"
        >
          <div>
            <p class="text-xs font-medium text-neutral-400">Daily Net</p>
            <motion.p
              :key="netDailyPhp"
              :initial="{ opacity: 0.65, y: 2 }"
              :animate="{ opacity: 1, y: 0 }"
              :transition="{ duration: 0.16, ease: EASE }"
              class="mt-1.5 text-4xl font-bold tracking-tight tabular-nums text-white"
            >
              &#8369;{{ netDailyPhp.toLocaleString() }}
            </motion.p>
          </div>
          <div class="text-right">
            <p class="text-xs font-medium text-neutral-400">{{ workingDaysPerWeek }}-Day Net</p>
            <motion.p
              :key="netWeeklyPhp"
              :initial="{ opacity: 0.65, y: 2 }"
              :animate="{ opacity: 1, y: 0 }"
              :transition="{ duration: 0.16, ease: EASE }"
              class="mt-1.5 text-2xl font-bold tabular-nums text-emerald-400"
            >
              &#8369;{{ netWeeklyPhp.toLocaleString() }}
            </motion.p>
          </div>
        </div>

        <dl class="relative mt-6 space-y-3 text-sm">
          <div class="flex items-center justify-between">
            <dt class="text-neutral-400">Gross cash</dt>
            <dd class="font-semibold tabular-nums text-white">
              &#8369;{{ grossDailyPhp.toLocaleString() }}
            </dd>
          </div>
          <div class="flex items-center justify-between">
            <dt class="text-neutral-400">Fee ({{ activeTier?.ratePercent }}%)</dt>
            <dd class="font-semibold tabular-nums text-neutral-300">
              -&#8369;{{ commissionDeductionPhp.toLocaleString() }}
            </dd>
          </div>
        </dl>
      </div>
    </div>
  </section>
</template>

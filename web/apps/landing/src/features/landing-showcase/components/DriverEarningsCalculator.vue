<script setup lang="ts">
import { computed, ref } from 'vue'
import { COMMISSION_TIERS } from '@/features/landing-showcase/data/landingContent'
import UiIcon from '@/shared/components/UiIcon.vue'

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
    class="rounded-3xl border border-slate-200 bg-white p-6 shadow-xl shadow-slate-900/5 sm:p-8"
  >
    <div class="flex flex-wrap items-start justify-between gap-3">
      <div>
        <p class="text-xs font-bold uppercase tracking-wider text-emerald-700">
          Driver Earnings Estimator (PHP)
        </p>
        <h2 id="driver-earnings-heading" class="mt-1 text-2xl font-extrabold text-[#090d16]">
          See your daily cash &amp; QRPh fee breakdown
        </h2>
      </div>
      <span class="rounded-full bg-emerald-50 px-3 py-1 text-xs font-bold text-emerald-800">
        Min wallet balance &#8369;50
      </span>
    </div>

    <div class="mt-6 grid gap-8 lg:grid-cols-12">
      <div class="space-y-5 lg:col-span-6">
        <div>
          <span class="block text-xs font-bold uppercase tracking-wider text-slate-600">
            1. Select commission tier
          </span>
          <div class="mt-2 grid gap-2 sm:grid-cols-3">
            <button
              v-for="tier in COMMISSION_TIERS"
              :key="tier.id"
              type="button"
              class="rounded-2xl border p-3 text-left transition-all"
              :class="
                selectedTierId === tier.id
                  ? 'border-emerald-600 bg-emerald-50 ring-1 ring-emerald-600/20'
                  : 'border-slate-200 bg-white hover:border-slate-300'
              "
              @click="selectedTierId = tier.id"
            >
              <p class="text-xs font-bold text-[#090d16]">{{ tier.tierName }}</p>
              <p class="mt-1 text-lg font-extrabold tabular-nums text-emerald-800">
                {{ tier.ratePercent }}% fee
              </p>
              <p class="mt-0.5 text-[11px] text-slate-600">{{ tier.vehicleFocus }}</p>
            </button>
          </div>
        </div>

        <div>
          <div class="flex items-center justify-between text-xs font-semibold text-slate-700">
            <label for="calc-daily-trips">2. Completed trips per day</label>
            <span class="font-extrabold tabular-nums text-[#090d16]">{{ dailyTrips }} trips</span>
          </div>
          <input
            id="calc-daily-trips"
            v-model.number="dailyTrips"
            type="range"
            min="6"
            max="36"
            step="1"
            class="mt-2 w-full accent-emerald-700"
          />
        </div>

        <div>
          <div class="flex items-center justify-between text-xs font-semibold text-slate-700">
            <label for="calc-avg-fare">3. Average Pagadian trip fare</label>
            <span class="font-extrabold tabular-nums text-[#090d16]">&#8369;{{ avgFarePhp }}</span>
          </div>
          <input
            id="calc-avg-fare"
            v-model.number="avgFarePhp"
            type="range"
            min="30"
            max="120"
            step="5"
            class="mt-2 w-full accent-emerald-700"
          />
        </div>

        <div>
          <span class="block text-xs font-semibold text-slate-700">4. Riding days per week</span>
          <div class="mt-2 flex gap-2">
            <button
              v-for="days in [5, 6, 7]"
              :key="days"
              type="button"
              class="rounded-xl border px-4 py-2 text-xs font-bold tabular-nums transition-colors"
              :class="
                workingDaysPerWeek === days
                  ? 'border-[#090d16] bg-[#090d16] text-white'
                  : 'border-slate-200 bg-white text-slate-700 hover:bg-slate-50'
              "
              @click="workingDaysPerWeek = days"
            >
              {{ days }} days / wk
            </button>
          </div>
        </div>
      </div>

      <div
        class="rounded-3xl border border-emerald-200 bg-linear-to-br from-emerald-50 via-white to-slate-50 p-6 lg:col-span-6"
      >
        <p class="text-xs font-bold uppercase tracking-wider text-emerald-800">
          Estimated Net Take-Home ({{ activeTier?.tierName }})
        </p>

        <div
          class="mt-3 flex flex-wrap items-baseline justify-between gap-4 border-b border-emerald-200/70 pb-5"
        >
          <div>
            <p class="text-4xl font-extrabold tracking-tight tabular-nums text-[#090d16]">
              &#8369;{{ netDailyPhp.toLocaleString() }}
            </p>
            <p class="mt-1 text-xs font-medium text-slate-600">
              Net cash kept per day (before fuel)
            </p>
          </div>
          <div class="text-right">
            <p class="text-xs font-semibold uppercase tracking-wider text-slate-500">
              {{ workingDaysPerWeek }}-day week
            </p>
            <p class="text-2xl font-extrabold tabular-nums text-emerald-800">
              &#8369;{{ netWeeklyPhp.toLocaleString() }}
            </p>
          </div>
        </div>

        <dl class="mt-5 space-y-3 text-sm">
          <div class="flex items-center justify-between">
            <dt class="text-slate-600">Gross cash collected from passengers</dt>
            <dd class="font-bold tabular-nums text-[#090d16]">
              &#8369;{{ grossDailyPhp.toLocaleString() }}
            </dd>
          </div>
          <div class="flex items-center justify-between">
            <dt class="text-slate-600">QRPh wallet deduction ({{ activeTier?.ratePercent }}%)</dt>
            <dd class="font-bold tabular-nums text-amber-800">
              -&#8369;{{ commissionDeductionPhp.toLocaleString() }}
            </dd>
          </div>
        </dl>

        <div
          class="mt-6 flex items-start gap-2.5 rounded-2xl border border-slate-200 bg-white p-4 text-xs text-slate-700"
        >
          <UiIcon name="qr-code" size-class="mt-0.5 h-4 w-4 text-emerald-700" />
          <p>
            Suggested QRPh top-up for this volume: keep at least
            <strong class="tabular-nums text-[#090d16]"
              >&#8369;{{ Math.max(100, commissionDeductionPhp).toLocaleString() }}</strong
            >
            in your prepaid wallet via GCash, Maya, BDO, or BPI InstaPay so bids never pause.
          </p>
        </div>
      </div>
    </div>
  </section>
</template>

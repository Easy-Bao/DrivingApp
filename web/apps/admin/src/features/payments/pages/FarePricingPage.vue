<script setup lang="ts">
import { ref } from 'vue'
import { Icon } from '@iconify/vue'

const pricingRules = ref([
  {
    tier: 'Economy',
    baseFare: 3.5,
    perKm: 1.25,
    perMinute: 0.25,
    minimumFare: 5.0,
    cancellationFee: 3.0,
    nightSurgeMultiplier: 1.25,
  },
  {
    tier: 'Comfort',
    baseFare: 5.0,
    perKm: 1.75,
    perMinute: 0.35,
    minimumFare: 7.5,
    cancellationFee: 5.0,
    nightSurgeMultiplier: 1.3,
  },
  {
    tier: 'XL Family',
    baseFare: 7.5,
    perKm: 2.4,
    perMinute: 0.45,
    minimumFare: 10.0,
    cancellationFee: 7.0,
    nightSurgeMultiplier: 1.4,
  },
  {
    tier: 'Executive Black',
    baseFare: 12.0,
    perKm: 3.5,
    perMinute: 0.75,
    minimumFare: 20.0,
    cancellationFee: 10.0,
    nightSurgeMultiplier: 1.5,
  },
])

const actionToast = ref<string | null>(null)

function savePricing() {
  actionToast.value = 'Pricing calculation matrix updated across all active dispatch clusters.'
  setTimeout(() => {
    actionToast.value = null
  }, 4000)
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-neutral-900 tracking-tight">
          Fare Calculation & Pricing Matrix
        </h1>
        <p class="text-sm text-neutral-500 mt-1">
          Configure algorithmic base fares, distance per-kilometer rates, duration rates, and
          minimum fare thresholds.
        </p>
      </div>
      <button
        type="button"
        class="px-3.5 py-2 bg-neutral-900 hover:bg-neutral-800 text-white rounded-lg text-xs font-semibold transition-colors flex items-center space-x-2"
        @click="savePricing"
      >
        <Icon icon="lucide:save" />
        <span>Save Pricing Matrix</span>
      </button>
    </div>

    <div
      v-if="actionToast"
      class="p-4 rounded-xl bg-neutral-900 text-white text-xs font-medium flex items-center justify-between shadow-lg"
    >
      <div class="flex items-center space-x-2">
        <Icon icon="lucide:check-circle" class="text-emerald-400 text-base" />
        <span>{{ actionToast }}</span>
      </div>
      <button type="button" @click="actionToast = null">
        <Icon icon="lucide:x" />
      </button>
    </div>

    <div class="bg-white border border-neutral-200 rounded-xl shadow-2xs overflow-hidden">
      <div class="p-4 border-b border-neutral-100 flex items-center justify-between">
        <h2 class="font-bold text-sm text-neutral-900">Tier Fare Constants</h2>
        <span class="text-xs text-neutral-400">Values in USD currency</span>
      </div>

      <table class="w-full text-left text-xs">
        <thead
          class="bg-neutral-50 text-neutral-500 uppercase border-b border-neutral-100 font-semibold"
        >
          <tr>
            <th class="py-3 px-4">Service Tier</th>
            <th class="py-3 px-4">Base Fare ($)</th>
            <th class="py-3 px-4">Rate / Km ($)</th>
            <th class="py-3 px-4">Rate / Min ($)</th>
            <th class="py-3 px-4">Min Trip Fare ($)</th>
            <th class="py-3 px-4">Cancellation Fee ($)</th>
            <th class="py-3 px-4 text-right">Night Multiplier</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-100">
          <tr
            v-for="rule in pricingRules"
            :key="rule.tier"
            class="hover:bg-neutral-50/70 transition-colors"
          >
            <td class="py-3 px-4 font-bold text-neutral-900">{{ rule.tier }}</td>
            <td class="py-3 px-4">
              <input
                v-model.number="rule.baseFare"
                type="number"
                step="0.25"
                class="w-20 px-2 py-1 bg-neutral-50 border border-neutral-200 rounded-md font-mono"
              />
            </td>
            <td class="py-3 px-4">
              <input
                v-model.number="rule.perKm"
                type="number"
                step="0.05"
                class="w-20 px-2 py-1 bg-neutral-50 border border-neutral-200 rounded-md font-mono"
              />
            </td>
            <td class="py-3 px-4">
              <input
                v-model.number="rule.perMinute"
                type="number"
                step="0.05"
                class="w-20 px-2 py-1 bg-neutral-50 border border-neutral-200 rounded-md font-mono"
              />
            </td>
            <td class="py-3 px-4">
              <input
                v-model.number="rule.minimumFare"
                type="number"
                step="0.50"
                class="w-20 px-2 py-1 bg-neutral-50 border border-neutral-200 rounded-md font-mono"
              />
            </td>
            <td class="py-3 px-4">
              <input
                v-model.number="rule.cancellationFee"
                type="number"
                step="0.50"
                class="w-20 px-2 py-1 bg-neutral-50 border border-neutral-200 rounded-md font-mono"
              />
            </td>
            <td class="py-3 px-4 text-right font-bold text-neutral-900">
              {{ rule.nightSurgeMultiplier }}x
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
